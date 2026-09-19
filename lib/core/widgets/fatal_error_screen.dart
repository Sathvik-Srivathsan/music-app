import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_collection/core/constants/app_colors.dart';

/// Shown when the app cannot initialize (e.g. Supabase config/network failure
/// during startup). Replaces what would otherwise be a silent crash before the
/// UI appears, so the user gets a clear, replayable message instead of
/// "app won't open".
class FatalErrorScreen extends StatelessWidget {
  const FatalErrorScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 64, color: AppColors.error),
                const SizedBox(height: 20),
                const Text(
                  'Unable to start',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    // Exits the app so the user can reopen and retry once the
                    // transient network failure clears.
                    SystemNavigator.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Close app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
