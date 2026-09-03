import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider.dart';
import '../constants/app_colors.dart';

/// Owner-only entry gate. One centered "Login through GitHub" button (one-click
/// OAuth). If Supabase's `before-user-created` Auth Hook rejects the account, a
/// red "Access denied" message appears above the button and the user may retry.
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isBusy = auth.status == AuthStatus.loading;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Music Collection',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Owner sign-in required',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 36),
                // Red "Access denied" sits above the button on rejection.
                if (auth.status == AuthStatus.denied) ...[
                  const Text(
                    'Access denied',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // A GitHub OAuth did not leave the app in a good state (e.g.
                // the flow was cancelled) — inform before offering a retry.
                if (auth.status == AuthStatus.unauthenticated) ...[
                  const Text(
                    'Sign in with GitHub to manage the database.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: isBusy ? null : auth.signInWithGitHub,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.electricBlue,
                      foregroundColor: AppColors.textPrimary,
                      disabledBackgroundColor: AppColors.inputBackground,
                      disabledForegroundColor: AppColors.textHint,
                    ),
                    child: isBusy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : const Text(
                            'Login through GitHub',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}