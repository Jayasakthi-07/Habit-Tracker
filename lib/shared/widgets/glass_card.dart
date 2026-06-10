import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The cornerstone surface of the Aurora design language.
///
/// Dark mode: a layered ink card with a hairline border and a faint top sheen.
/// Light mode: a crisp white card floating on soft, airy shadows. Hoverable
/// cards lift slightly. BackdropFilter blur is only applied when [blur] > 0,
/// so grids of cards stay cheap to composite.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppSpacing.radiusLg,
    this.blur = 0,
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

    final inner = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        gradient: widget.gradient ?? AppColors.glassGradient,
      ),
      child: widget.child,
    );

    Widget card = AnimatedContainer(
      duration: AppSpacing.fast,
      curve: Curves.easeOut,
      width: widget.width,
      height: widget.height,
      transform: Matrix4.translationValues(0, hover ? -3 : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: radius,
        color: widget.blur > 0
            ? AppColors.alpha(AppColors.card, AppColors.isLight ? 0.72 : 0.66)
            : AppColors.card,
        border: Border.all(
          color: hover
              ? (widget.glowColor != null
                  ? AppColors.alpha(widget.glowColor!, 0.55)
                  : AppColors.borderStrong)
              : (widget.borderColor ??
                  (widget.glowColor != null
                      ? AppColors.alpha(widget.glowColor!, 0.35)
                      : AppColors.border)),
          width: 1,
        ),
        boxShadow: [
          ...AppShadows.card,
          if (widget.glowColor != null)
            ...AppShadows.glow(widget.glowColor!,
                strength: hover ? 0.20 : 0.12),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: widget.blur > 0
            ? BackdropFilter(
                filter:
                    ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
                child: inner,
              )
            : inner,
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
