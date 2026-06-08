import 'package:flutter/material.dart';

/// Central color palette for the Aura Habits design system.
///
/// The palette is intentionally dark, high-contrast and neon-accented to give
/// the application a premium, futuristic feel that stands apart from stock
/// Material habit trackers.
abstract class AppColors {
  // ---- Brand accents ----
  static const Color primary = Color(0xFF00FF88); // electric mint
  static const Color secondary = Color(0xFF00D4FF); // cyan

  // ---- Surfaces ----
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color card = Color(0xFF1C1C1C);
  static const Color cardElevated = Color(0xFF242424);

  // ---- Text ----
  static const Color text = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFA0A0A0);
  static const Color faint = Color(0xFF6B6B6B);

  // ---- Semantic ----
  static const Color success = Color(0xFF00FF88);
  static const Color warning = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF5A6E);
  static const Color info = Color(0xFF00D4FF);
  static const Color partial = Color(0xFFFFC857);
  static const Color skipped = Color(0xFF7A7A8C);

  // ---- Hairlines / borders ----
  static const Color border = Color(0x1AFFFFFF); // 10% white
  static const Color borderStrong = Color(0x33FFFFFF); // 20% white

  // ---- Ambient background aura (premium indigo → violet, not green) ----
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

  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1C1C1C), Color(0xFF141414)],
  );

  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x14FFFFFF), Color(0x05FFFFFF)],
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
