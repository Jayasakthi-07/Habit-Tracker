import 'package:flutter/widgets.dart';

import 'app_colors.dart';

/// Spacing, radius and motion tokens shared across the UI for visual rhythm.
abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 28;
  static const double radiusPill = 999;

  // Mobile pages use tighter horizontal padding than the desktop's 24px all-round.
  static const EdgeInsets pagePadding =
      EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration slow = Duration(milliseconds: 550);

  static const Curve ease = Curves.easeOutCubic;
  static const Curve spring = Curves.easeOutBack;
}

/// Reusable shadow presets — theme-aware so light mode gets soft, airy
/// elevation instead of the heavy ink shadows dark mode needs.
abstract class AppShadows {
  static List<BoxShadow> get soft => AppColors.isLight
      ? const [
          BoxShadow(
              color: Color(0x14101828), blurRadius: 16, offset: Offset(0, 6)),
        ]
      : const [
          BoxShadow(
              color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
        ];

  static List<BoxShadow> get card => AppColors.isLight
      ? const [
          BoxShadow(
              color: Color(0x0A101828), blurRadius: 6, offset: Offset(0, 2)),
          BoxShadow(
              color: Color(0x0F101828),
              blurRadius: 24,
              spreadRadius: -6,
              offset: Offset(0, 12)),
        ]
      : const [
          BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 20,
              spreadRadius: -10,
              offset: Offset(0, 12)),
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

  /// Elevation under filled accent elements (buttons, FAB, hero) — a colored
  /// shadow reads far more premium than a grey one.
  static List<BoxShadow> get accent => [
        BoxShadow(
          color: AppColors.fillStart.withValues(alpha: AppColors.isLight ? 0.32 : 0.38),
          blurRadius: 18,
          spreadRadius: -6,
          offset: const Offset(0, 8),
        ),
      ];
}
