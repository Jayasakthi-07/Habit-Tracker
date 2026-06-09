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

  // Mobile pages use tighter horizontal padding than the desktop's 24px all-round.
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 320);
  static const Duration slow = Duration(milliseconds: 600);
}

/// Reusable shadow presets.
abstract class AppShadows {
  static List<BoxShadow> soft = [
    const BoxShadow(
      color: Color(0x4D000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static List<BoxShadow> card = [
    const BoxShadow(
      color: Color(0x40000000),
      blurRadius: 20,
      spreadRadius: -10,
      offset: Offset(0, 12),
    ),
  ];

  /// A subtle accent halo. Kept minimal and tight so the UI reads crisp rather
  /// than blurry/neon (see HANDOVER §6 — user dislikes heavy glow).
  static List<BoxShadow> glow(Color color, {double strength = 0.16}) => [
        BoxShadow(
          color: color.withValues(alpha: strength),
          blurRadius: 14,
          spreadRadius: -10,
          offset: const Offset(0, 3),
        ),
      ];
}
