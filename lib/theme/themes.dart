import 'package:flutter/material.dart';
import '../data/settings_repo.dart';

class AppColors {
  static const tiffanyBlue = Color(0xFF00C7BE);
  static const oxfordBlue = Color(0xFF0E1F40);
  static const pictonBlue = Color(0xFF4FB8E6);
  static const shockingPink = Color(0xFFFF3EB5);
  static const folly = Color(0xFFFF0F5C);
}

ThemeData themeFor(AppTheme t) {
  final scheme = switch (t) {
    AppTheme.neutral => const ColorScheme.dark(
        primary: AppColors.tiffanyBlue,
        onPrimary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      ),
    AppTheme.boy => const ColorScheme.dark(
        primary: AppColors.pictonBlue,
        onPrimary: Colors.black,
        surface: AppColors.oxfordBlue,
        onSurface: Colors.white,
      ),
    AppTheme.girl => const ColorScheme.dark(
        primary: AppColors.shockingPink,
        onPrimary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        secondary: AppColors.folly,
      ),
  };

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
  );
}
