import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../network/supabase_client.dart';

/// Whether the app can be operated (owner signed in, or the anonymous boot
/// state) — a coarse representation of the auth gate on top of Supabase.
enum AuthStatus { loading, unauthenticated, authenticated, denied }

/// Drives the owner-only GitHub OAuth gate.
///
/// The app data is anonymous/public, but **writes** are owner-only. A real
/// session arrives via GitHub OAuth (PKCE, the SDK default on web) and is
/// persisted by `supabase_flutter` automatically. Access is gated at the router,
/// and the `before-user-created` Supabase Auth Hook rejects (HTTP 403) anyone
/// who is not the configured owner, surfacing an "Access denied" error to this
/// class.
///
/// How denial is detected (robustly):
///   * A streaming error on [GoTrueClient.onAuthStateChange]. The SDK forwards
///     the hook's error into that stream's `onError` channel.
///   * The callback URL may retain `error` / `error_code` / `error_description`
///     query parameters on web (the SDK clears them only on success). If those
///     are present and no session exists, we treat the attempt as denied.
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    try {
      _subscription = SupabaseService.auth.onAuthStateChange.listen(
        _onAuthState,
        onError: _onAuthError,
      );
      // Check for a stale/denied OAuth callback left in the URL (web only). A
      // BehaviorSubject replays the latest *data* event, but NOT errors, so an
      // error that fired before we subscribed is picked up here instead.
      _checkUrlForDenial();
    } catch (_) {
      // Supabase not initialized (e.g. build-time/test). Treat as
      // unauthenticated so the login gate is shown.
      _status = AuthStatus.unauthenticated;
    }
  }

  StreamSubscription<AuthState>? _subscription;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  void _onAuthState(AuthState state) {
    if (state.session != null ||
        state.event == AuthChangeEvent.signedIn) {
      _setStatus(AuthStatus.authenticated);
    } else if (state.event == AuthChangeEvent.signedOut) {
      _setStatus(AuthStatus.unauthenticated);
    }
    // InitialSession with a null session stays unauthenticated; denied is
    // intentionally not overridden here so the "Access denied" screen persists
    // until the user retries.
  }

  void _onAuthError(Object error, StackTrace stackTrace) {
    // A hook rejection (or any OAuth failure) with no session means the owner
    // gate blocked the sign-in attempt.
    if (!isAuthenticated) {
      _setStatus(AuthStatus.denied);
    }
  }

  void _checkUrlForDenial() {
    if (!kIsWeb) return;
    final params = Uri.base.queryParameters;
    final hasAuthError = params.containsKey('error') ||
        params.containsKey('error_code') ||
        params.containsKey('error_description');
    if (hasAuthError && !isAuthenticated) {
      // Deferred so a fresh first build never syncs a change during build.
      scheduleMicrotask(() => _setStatus(AuthStatus.denied));
    }
  }

  /// Starts the one-click GitHub OAuth flow (owner-only). On web the page
  /// navigates to GitHub and comes back to the app with the auth callback, so
  /// the outcome is observed via [onAuthStateChange], not this method's return.
  Future<void> signInWithGitHub() async {
    _setStatus(AuthStatus.loading);
    try {
      // redirectTo is left null on web so Supabase uses the configured Site URL
      // as the callback (see the Dashboard URL Configuration step).
      await SupabaseService.auth.signInWithOAuth(
        OAuthProvider.github,
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );
      // A (rare) immediate error leaves no session; fall through to denied.
    } on AuthException {
      _setStatus(AuthStatus.denied);
    } catch (_) {
      _setStatus(AuthStatus.unauthenticated);
    }
  }

  void _setStatus(AuthStatus next) {
    if (_status == next) return;
    _status = next;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}