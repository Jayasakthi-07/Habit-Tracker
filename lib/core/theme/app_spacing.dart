import 'package:flutter/widgets.dart';

/// Spacing, radius and shadow tokens shared across the UI for visual rhythm.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 22;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  static const EdgeInsets pagePadding = EdgeInsets.all(xl);
  static const EdgeInsets cardPadding = EdgeInsets.all(xl);

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
}

/// Reusable shadow presets.
abstract class AppShadows {
  static List<BoxShadow> soft = [
    const BoxShadow(
      color: Color(0x66000000),
      blurRadius: 24,
      offset: Offset(0, 12),
    ),
  ];

  static List<BoxShadow> card = [
    const BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 30,
      spreadRadius: -8,
      offset: Offset(0, 18),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double strength = 0.45}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 28,
          spreadRadius: -4,
          offset: const Offset(0, 6),
        ),
      ];
}
