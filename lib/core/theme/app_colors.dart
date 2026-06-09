import 'package:flutter/material.dart';

/// Central color palette for the Aura Habits design system.
///
/// **Theme-aware:** brand accents (mint/cyan and the semantic colors) are the
/// same in light and dark — they are the product's identity. Only the
/// *surface*, *text* and *border* colors flip with [brightness], which the app
/// sets when the user changes theme. Because those are runtime getters, they
/// can't be used in `const` expressions.
abstract class AppColors {
  /// Current UI brightness. Set by the theme controller before the first frame
  /// and whenever the user switches theme; widgets read the getters below.
  static Brightness brightness = Brightness.dark;
  static bool get isLight => brightness == Brightness.light;

  // ---- Brand accents (constant across themes) ----
  static const Color primary = Color(0xFF00FF88); // electric mint
  static const Color secondary = Color(0xFF00D4FF); // cyan

  // ---- Surfaces (theme-aware) ----
  static Color get background => isLight ? _lBackground : _dBackground;
  static Color get surface => isLight ? _lSurface : _dSurface;
  static Color get card => isLight ? _lCard : _dCard;
  static Color get cardElevated => isLight ? _lCardElevated : _dCardElevated;

  static const Color _dBackground = Color(0xFF0A0A0A);
  static const Color _dSurface = Color(0xFF141414);
  static const Color _dCard = Color(0xFF1C1C1C);
  static const Color _dCardElevated = Color(0xFF242424);
  static const Color _lBackground = Color(0xFFF4F5F7);
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lCard = Color(0xFFFFFFFF);
  static const Color _lCardElevated = Color(0xFFEFF1F4);

  // ---- Text (theme-aware) ----
  static Color get text => isLight ? _lText : _dText;
  static Color get muted => isLight ? _lMuted : _dMuted;
  static Color get faint => isLight ? _lFaint : _dFaint;

  static const Color _dText = Color(0xFFFFFFFF);
  static const Color _dMuted = Color(0xFFA0A0A0);
  static const Color _dFaint = Color(0xFF6B6B6B);
  static const Color _lText = Color(0xFF0E1116);
  static const Color _lMuted = Color(0xFF5B6470);
  static const Color _lFaint = Color(0xFF9AA2AD);

  // ---- Hairlines / borders (theme-aware) ----
  static Color get border => isLight ? _lBorder : _dBorder;
  static Color get borderStrong => isLight ? _lBorderStrong : _dBorderStrong;

  static const Color _dBorder = Color(0x1AFFFFFF); // 10% white
  static const Color _dBorderStrong = Color(0x33FFFFFF); // 20% white
  static const Color _lBorder = Color(0x14000000); // 8% black
  static const Color _lBorderStrong = Color(0x24000000); // ~14% black

  // ---- Semantic (constant) ----
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF5A6E);
  static const Color info = Color(0xFF00D4FF);
  static const Color partial = Color(0xFFFFC857);
  static const Color skipped = Color(0xFF7A7A8C);

  // ---- Ambient background aura (constant) ----
  static const Color ambientA = Color(0xFF4F46E5); // indigo
  static const Color ambientB = Color(0xFF7C3AED); // violet
  static const Color ambientC = Color(0xFF2563EB); // blue

  // ---- Gradients ----
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF00FF88), Color(0xFF00D4FF)],
  );

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? const [Color(0xFFFFFFFF), Color(0xFFF1F3F6)]
            : const [Color(0xFF1C1C1C), Color(0xFF141414)],
      );

  /// Subtle glass sheen — a faint light highlight in dark mode, a faint dark
  /// highlight in light mode (so cards read crisp on both).
  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? const [Color(0x0D000000), Color(0x03000000)]
            : const [Color(0x14FFFFFF), Color(0x05FFFFFF)],
      );

  /// Returns a translucent version of [color].
  static Color alpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  /// A small curated set of accent colors users can assign to habits.
  static const List<Color> habitPalette = [
    Color(0xFF00FF88),
    Color(0xFF00D4FF),
    Color(0xFFFFC857),
    Color(0xFFFF5A6E),
    Color(0xFFB388FF),
    Color(0xFFFF8A65),
    Color(0xFF4DD0E1),
    Color(0xFFF06292),
    Color(0xFFAED581),
    Color(0xFF9575CD),
  ];
}
