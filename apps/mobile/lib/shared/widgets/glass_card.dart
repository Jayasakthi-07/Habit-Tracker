import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The cornerstone surface of the Aurora design language.
///
/// Dark mode: a layered ink card with a hairline border and a faint top sheen.
/// Light mode: a crisp white card floating on soft, airy shadows.
/// Interactive cards get a tactile press-scale. BackdropFilter blur is only
/// applied when [blur] > 0 — list cells pass 0 so scrolling stays buttery.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppSpacing.radiusLg,
    this.blur = 0,
    this.onTap,
    this.onLongPress,
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
  final VoidCallback? onLongPress;
  final Color? borderColor;
  final Color? glowColor;
  final Gradient? gradient;
  final double? width;
  final double? height;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.radius);
    final interactive = widget.onTap != null || widget.onLongPress != null;

    final inner = Container(
      padding: widget.padding,
      decoration: BoxDecoration(
        // A faint sheen on top of the opaque card color gives depth without
        // the muddiness of pure translucency.
        gradient: widget.gradient ?? AppColors.glassGradient,
      ),
      child: widget.child,
    );

    Widget card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppSpacing.fast,
      curve: Curves.easeOut,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: widget.blur > 0
              ? AppColors.alpha(AppColors.card, AppColors.isLight ? 0.72 : 0.66)
              : AppColors.card,
          border: Border.all(
            color: widget.borderColor ??
                (widget.glowColor != null
                    ? AppColors.alpha(widget.glowColor!, 0.35)
                    : AppColors.border),
            width: 1,
          ),
          boxShadow: [
            ...AppShadows.card,
            if (widget.glowColor != null)
              ...AppShadows.glow(widget.glowColor!, strength: 0.14),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: widget.blur > 0
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: widget.blur, sigmaY: widget.blur),
                  child: inner,
                )
              : inner,
        ),
      ),
    );

    if (interactive) {
      card = GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: card,
      );
    }

    return card;
  }
}
