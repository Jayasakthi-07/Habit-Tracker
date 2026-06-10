import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Typography scale built on Inter (UI) + Space Grotesk (numerals) for a
/// clean, premium look. Headlines carry heavier weights and tight tracking.
///
/// Google Fonts caches the typeface after first load and falls back to the
/// platform default if offline, so this is safe for an offline-first app.
abstract class AppTypography {
  static TextTheme textTheme(TextTheme base) {
    return GoogleFonts.interTextTheme(base).copyWith(
      displayLarge: _f(40, FontWeight.w800, height: 1.08, tracking: -1.2),
      displayMedium: _f(32, FontWeight.w800, height: 1.12, tracking: -0.8),
      displaySmall: _f(28, FontWeight.w700, tracking: -0.6),
      headlineMedium: _f(24, FontWeight.w700, tracking: -0.5),
      headlineSmall: _f(20, FontWeight.w700, tracking: -0.3),
      titleLarge: _f(18, FontWeight.w700, tracking: -0.2),
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
    Color? color,
    double? height,
    double tracking = 0,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.text,
      height: height,
      letterSpacing: tracking,
    );
  }

  /// Tabular figures for animated counters / stats.
  static TextStyle numeric(double size,
      {FontWeight weight = FontWeight.w700, Color? color}) {
    return GoogleFonts.spaceGrotesk(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.text,
      letterSpacing: -0.5,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Tiny uppercase section label — the quiet premium detail.
  static TextStyle overline({Color? color}) {
    return GoogleFonts.inter(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.6,
      color: color ?? AppColors.faint,
    );
  }
}
