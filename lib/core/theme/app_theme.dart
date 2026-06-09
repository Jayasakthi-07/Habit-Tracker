import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Assembles the global [ThemeData] from the design tokens, for either
/// brightness. Because [AppColors] surface/text colors are runtime getters keyed
/// on [AppColors.brightness], we build ONE theme at a time (the app sets the
/// brightness and rebuilds on toggle) rather than passing both theme+darkTheme.
abstract class AppTheme {
  static ThemeData get dark => themeFor(Brightness.dark);
  static ThemeData get light => themeFor(Brightness.light);

  static ThemeData themeFor(Brightness brightness) {
    // Ensure token getters resolve to the brightness we're building for.
    AppColors.brightness = brightness;
    final isLight = brightness == Brightness.light;
    final base = ThemeData(useMaterial3: true, brightness: brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: const Color(0xFF002417),
      secondary: AppColors.secondary,
      onSecondary: const Color(0xFF00222B),
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
      dividerTheme:
          DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: AppColors.muted, size: 22),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        titleTextStyle: AppTypography.textTheme(base.textTheme).titleLarge,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.cardElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        textStyle: TextStyle(color: AppColors.text, fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.alpha(Colors.black, 0.03)
            : AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: AppColors.faint),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
