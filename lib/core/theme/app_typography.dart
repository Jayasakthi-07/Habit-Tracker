import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale built on the Inter typeface for a clean, modern look.
///
/// Google Fonts caches the typeface after first load and falls back to the
/// platform default if offline, so this is safe for an offline-first app.
abstract class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: _f(40, FontWeight.w700, height: 1.1),
      displayMedium: _f(32, FontWeight.w700, height: 1.15),
      displaySmall: _f(28, FontWeight.w600),
      headlineMedium: _f(24, FontWeight.w600),
      headlineSmall: _f(20, FontWeight.w600),
      titleLarge: _f(18, FontWeight.w600),
      titleMedium: _f(16, FontWeight.w600),
      titleSmall: _f(14, FontWeight.w600, color: AppColors.muted),
      bodyLarge: _f(15, FontWeight.w400, height: 1.5),
      bodyMedium: _f(14, FontWeight.w400, height: 1.5, color: AppColors.muted),
      bodySmall: _f(12, FontWeight.w400, color: AppColors.muted),
      labelLarge: _f(14, FontWeight.w600),
      labelMedium: _f(12, FontWeight.w500, color: AppColors.muted),
      labelSmall: _f(11, FontWeight.w500, color: AppColors.faint),
    );
  }

  static TextStyle _f(
    double size,
    FontWeight weight, {
    Color color = AppColors.text,
    double? height,
    double letterSpacing = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Tabular figures for animated counters / stats.
  static TextStyle numeric(double size, {FontWeight weight = FontWeight.w700, Color color = AppColors.text}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
