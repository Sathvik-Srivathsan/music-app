import 'package:flutter/services.dart';

/// One place that resolves the app's Supabase config, so no caller ever has to
/// remember to pass `--dart-define` flags.
///
/// Priority order:
///   1. Compile-time `--dart-define` (how Vercel / `build.sh` inject values).
///   2. The bundled `.env` asset read at runtime (so a plain `flutter run -d
///      chrome` with a local `.env` works with zero flags).
///
/// Resolution is lazy + cached: [supabaseUrl] and [publishableKey] resolve once
/// on first access. [ensureLoaded] is awaited early in startup to guarantee the
/// file has been read before the Supabase client is initialized.
class AppEnv {
  AppEnv._();

  static const String _compileUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _compileKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static String? _fileUrl;
  static String? _fileKey;
  static bool _loaded = false;

  /// Reads the bundled `.env` asset once (best-effort). Compile-time defines
  /// still take precedence at [supabaseUrl]/[publishableKey].
  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final raw = await rootBundle.loadString('.env');
      _fileUrl = _valueFor(raw, 'SUPABASE_URL');
      _fileKey = _valueFor(raw, 'SUPABASE_PUBLISHABLE_KEY');
    } catch (_) {
      // No bundled .env (e.g. none existed at build time). Non-fatal; the
      // compile-time --dart-define source is checked next.
    }
  }

  static String? get supabaseUrl {
    if (_compileUrl.isNotEmpty) return _compileUrl;
    return _fileUrl;
  }

  static String? get publishableKey {
    if (_compileKey.isNotEmpty) return _compileKey;
    return _fileKey;
  }

  /// Parses `KEY=value` lines, trimming surrounding whitespace and ignoring
  /// blank lines and comments.
  static String? _valueFor(String raw, String key) {
    for (final rawLine in raw.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) continue;
      final name = line.substring(0, eq).trim();
      if (name != key) continue;
      var value = line.substring(eq + 1).trim();
      if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
        value = value.substring(1, value.length - 1);
      }
      return value;
    }
    return null;
  }
}