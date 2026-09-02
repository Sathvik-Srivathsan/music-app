import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background colors
  static const Color background = Color(0xFF121212);
  static const Color card = Color(0xFF1E1E1E);
  static const Color grid = Color(0xFF333333);
  static const Color surface = Color(0xFF252525);

  // Text colors
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color textHint = Color(0xFF666666);

  // CVD-safe 7-color chart palette
  static const Color electricBlue = Color(0xFF5B9BF5);
  static const Color vividOrange = Color(0xFFE8923E);
  static const Color teal = Color(0xFF3DD8C5);
  static const Color magentaRose = Color(0xFFE06B9E);
  static const Color amberGold = Color(0xFFF5C842);
  static const Color lavenderPurple = Color(0xFFA78BFA);
  static const Color coralRed = Color(0xFFEF6C5E);

  // Chart palette list
  static const List<Color> chartPalette = [
    electricBlue,
    vividOrange,
    teal,
    magentaRose,
    amberGold,
    lavenderPurple,
    coralRed,
  ];

  // Status colors
  static const Color active = Color(0xFF4CAF50);
  static const Color finished = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFEF5350);
  static const Color warning = Color(0xFFFFA726);
  static const Color success = Color(0xFF66BB6A);
  static const Color info = Color(0xFF42A5F5);

  // Border colors
  static const Color border = Color(0xFF444444);
  static const Color borderLight = Color(0xFF555555);

  // Input colors
  static const Color inputBackground = Color(0xFF2A2A2A);
  static const Color inputBorder = Color(0xFF555555);
  static const Color inputFocusBorder = Color(0xFF5B9BF5);
}
