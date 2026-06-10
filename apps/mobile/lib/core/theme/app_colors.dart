import 'package:flutter/material.dart';

/// Central color palette for the Aura Habits design system — the "Aurora"
/// design language.
///
/// One brand identity across both themes: a refined indigo → violet aurora.
/// Dark mode is a deep ink-navy (never flat black); light mode is porcelain
/// with crisp white cards. Surfaces, text, borders and accents are runtime
/// getters keyed on [brightness], so they can't be used in `const` expressions.
abstract class AppColors {
  /// Current UI brightness. Set by the theme controller before the first frame
  /// and whenever the user switches theme; widgets read the getters below.
  static Brightness brightness = Brightness.dark;
  static bool get isLight => brightness == Brightness.light;

  // ---- Brand accents ----
  // Dark uses the luminous 400-weight indigo/violet so accents glow against
  // ink; light uses the saturated 500-weight so they read crisp on white.
  static Color get primary => isLight ? _lPrimary : _dPrimary;
  static Color get secondary => isLight ? _lSecondary : _dSecondary;

  /// Foreground placed ON a filled [primary] / gradient surface. Gradient
  /// fills always use the 500-weight indigo→violet, so white works everywhere.
  static Color get onPrimary => Colors.white;

  static const Color _dPrimary = Color(0xFF818CF8); // indigo 400
  static const Color _dSecondary = Color(0xFFA78BFA); // violet 400
  static const Color _lPrimary = Color(0xFF6366F1); // indigo 500
  static const Color _lSecondary = Color(0xFF8B5CF6); // violet 500

  /// Saturated accent pair used for *fills* (buttons, FABs, hero surfaces) in
  /// both themes — deep enough that white text passes on top.
  static const Color fillStart = Color(0xFF6366F1);
  static const Color fillEnd = Color(0xFF8B5CF6);

  /// Third aurora hue, for charts and info accents.
  static Color get tertiary => isLight ? const Color(0xFF0EA5E9) : const Color(0xFF38BDF8);

  // ---- Surfaces ----
  static Color get background => isLight ? _lBackground : _dBackground;
  static Color get surface => isLight ? _lSurface : _dSurface;
  static Color get card => isLight ? _lCard : _dCard;
  static Color get cardElevated => isLight ? _lCardElevated : _dCardElevated;

  static const Color _dBackground = Color(0xFF0B0E15); // deep ink-navy
  static const Color _dSurface = Color(0xFF111522);
  static const Color _dCard = Color(0xFF151A28);
  static const Color _dCardElevated = Color(0xFF1C2233);
  static const Color _lBackground = Color(0xFFF6F7FB); // porcelain
  static const Color _lSurface = Color(0xFFFFFFFF);
  static const Color _lCard = Color(0xFFFFFFFF);
  static const Color _lCardElevated = Color(0xFFEEF1F7);

  // ---- Text ----
  static Color get text => isLight ? _lText : _dText;
  static Color get muted => isLight ? _lMuted : _dMuted;
  static Color get faint => isLight ? _lFaint : _dFaint;

  static const Color _dText = Color(0xFFF4F6FB);
  static const Color _dMuted = Color(0xFF98A1B3);
  static const Color _dFaint = Color(0xFF5C6577);
  static const Color _lText = Color(0xFF10131A);
  static const Color _lMuted = Color(0xFF5A6372);
  static const Color _lFaint = Color(0xFF98A0AD);

  // ---- Hairlines / borders ----
  static Color get border => isLight ? _lBorder : _dBorder;
  static Color get borderStrong => isLight ? _lBorderStrong : _dBorderStrong;

  static const Color _dBorder = Color(0x14FFFFFF); // 8% white
  static const Color _dBorderStrong = Color(0x29FFFFFF); // 16% white
  static const Color _lBorder = Color(0x14101828); // 8% ink
  static const Color _lBorderStrong = Color(0x26101828); // 15% ink

  // ---- Semantic ----
  // success tracks the brand accent so completed states stay on-brand (and the
  // light theme never shows green text, per design).
  static Color get success => primary;
  static Color get info => tertiary;
  static Color get warning => isLight ? const Color(0xFFD97706) : const Color(0xFFFBBF24);
  static Color get danger => isLight ? const Color(0xFFE11D48) : const Color(0xFFFB7185);
  static Color get partial => warning;
  static const Color skipped = Color(0xFF8A91A3);

  /// Streak flame — a warm ember that works on both themes.
  static Color get streak => isLight ? const Color(0xFFEA580C) : const Color(0xFFFB923C);

  // ---- Ambient background aura ----
  static const Color ambientA = Color(0xFF4F46E5); // indigo
  static const Color ambientB = Color(0xFF7C3AED); // violet
  static const Color ambientC = Color(0xFF0284C7); // deep sky

  // ---- Gradients ----
  /// Saturated fill gradient (buttons, FAB, hero) — white text on top.
  static LinearGradient get primaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fillStart, fillEnd],
      );

  /// Full aurora sweep, for hero surfaces and branding moments.
  static LinearGradient get auroraGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF9333EA)],
      );

  static LinearGradient get accentGlow => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [primary, secondary],
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? const [Color(0xFFFFFFFF), Color(0xFFF2F4F9)]
            : const [Color(0xFF171C2B), Color(0xFF11151F)],
      );

  /// Subtle sheen on cards — faint light in dark mode, faint ink in light.
  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isLight
            ? const [Color(0x07101828), Color(0x02101828)]
            : const [Color(0x12FFFFFF), Color(0x04FFFFFF)],
      );

  /// Returns a translucent version of [color].
  static Color alpha(Color color, double opacity) =>
      color.withValues(alpha: opacity);

  /// Display-time remap of legacy neon habit colors to their refined Aurora
  /// equivalents. Stored data is untouched, so sync stays consistent.
  static Color habitColor(int value) {
    const remap = <int, Color>{
      0xFF00FF88: Color(0xFF34D399), // neon mint -> emerald
      0xFF00D4FF: Color(0xFF22D3EE), // neon cyan -> cyan 400
      0xFFFFC857: Color(0xFFFBBF24), // mustard  -> amber 400
      0xFFFF5A6E: Color(0xFFFB7185), // neon red -> rose 400
      0xFFAED581: Color(0xFF4ADE80), // lime     -> green 400
    };
    return remap[value] ?? Color(value);
  }

  /// A small curated set of accent colors users can assign to habits.
  static const List<Color> habitPalette = [
    Color(0xFF818CF8), // indigo
    Color(0xFFA78BFA), // violet
    Color(0xFF38BDF8), // sky
    Color(0xFF22D3EE), // cyan
    Color(0xFF2DD4BF), // teal
    Color(0xFF34D399), // emerald
    Color(0xFFFBBF24), // amber
    Color(0xFFFB923C), // orange
    Color(0xFFFB7185), // rose
    Color(0xFFF472B6), // pink
  ];
}
