import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:music_collection/core/constants/app_colors.dart';

/// Best-effort native toasts. Wrapped in try/catch so a missing/misbehaving
/// platform channel (e.g. under `flutter test`) can never crash the app — a
/// toast is purely cosmetic feedback, never critical.
class ToastUtils {
  ToastUtils._();

  static void showSuccess(String message) =>
      _toast(message, AppColors.success);
  static void showError(String message) => _toast(message, AppColors.error);
  static void showWarning(String message) =>
      _toast(message, AppColors.warning);
  static void showInfo(String message) => _toast(message, AppColors.info);

  static void _toast(String message, Color color) {
    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: color,
        textColor: AppColors.textPrimary,
        fontSize: 14,
      ).catchError((_) {}); // errors surface on the returned future
    } catch (_) {
      // Ignore — toasts must never throw.
    }
  }
}
