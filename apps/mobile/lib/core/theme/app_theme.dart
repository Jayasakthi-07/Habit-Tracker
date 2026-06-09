import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the global dark [ThemeData] from the design tokens.
abstract class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final colorScheme = const ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Color(0xFF002417),
      secondary: AppColors.secondary,
      onSecondary: Color(0xFF00222B),
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
      onError: Colors.white,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      textTheme: AppTypography.textTheme(base.textTheme),
      splashFactory: InkRipple.splashFactory,
      dividerTheme: const DividerThemeData(
          color: AppColors.border, thickness: 1, space: 1),
      iconTheme: const IconThemeData(color: AppColors.muted, size: 22),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: const TextStyle(color: AppColors.text, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: const TextStyle(color: AppColors.faint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
