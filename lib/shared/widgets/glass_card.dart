import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A frosted-glass surface with a subtle gradient, hairline border and
/// optional hover elevation. The cornerstone of the app's glassmorphism style.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppSpacing.radiusLg,
    this.blur = 18,
    this.onTap,
    this.hoverable = false,
    this.borderColor,
    this.glowColor,
    this.gradient,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final double blur;
  final VoidCallback? onTap;
  final bool hoverable;
  final Color? borderColor;
  final Color? glowColor;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hover = widget.hoverable && _hovered;
    final radius = BorderRadius.circular(widget.radius);

    Widget card = AnimatedContainer(
      duration: AppSpacing.fast,
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      transform: Matrix4.translationValues(0, hover ? -3 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: widget.gradient ?? AppColors.glassGradient,
        border: Border.all(
          color: hover
              ? (widget.glowColor ?? AppColors.borderStrong)
              : (widget.borderColor ?? AppColors.border),
          width: 1,
        ),
        boxShadow: [
          ...AppShadows.card,
          if (hover && widget.glowColor != null)
            ...AppShadows.glow(widget.glowColor!, strength: 0.25),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: Container(
            padding: widget.padding,
            color: AppColors.alpha(AppColors.card, 0.55),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap != null || widget.hoverable) {
      card = MouseRegion(
        cursor: widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(onTap: widget.onTap, child: card),
      );
    }

    return card;
  }
}
