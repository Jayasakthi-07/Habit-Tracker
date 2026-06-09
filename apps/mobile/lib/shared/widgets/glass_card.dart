import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// A frosted-glass surface with a subtle gradient, hairline border and an
/// optional press feedback. The cornerstone of the app's glassmorphism style.
///
/// Mobile variant of the desktop [GlassCard]: hover is replaced with a tactile
/// press-scale, otherwise the look (blur 8, surface opacity 0.82, minimal glow)
/// matches the Windows app exactly.
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.radius = AppSpacing.radiusLg,
    this.blur = 8,
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

    Widget card = AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: AppSpacing.fast,
      curve: Curves.easeOut,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: widget.gradient ?? AppColors.glassGradient,
          border: Border.all(
            color: widget.borderColor ?? AppColors.border,
            width: 1,
          ),
          boxShadow: [
            ...AppShadows.card,
            if (widget.glowColor != null)
              ...AppShadows.glow(widget.glowColor!, strength: 0.10),
          ],
        ),
        // Skip the (GPU-expensive) BackdropFilter when blur <= 0. List cells
        // pass blur:0 so long scrolling lists stay buttery — the gradient +
        // translucent surface still read as glass.
        child: widget.blur <= 0
            ? ClipRRect(
                borderRadius: radius,
                child: Container(
                  padding: widget.padding,
                  color: AppColors.alpha(
                      AppColors.card, AppColors.isLight ? 0.92 : 0.86),
                  child: widget.child,
                ),
              )
            : ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                      sigmaX: widget.blur, sigmaY: widget.blur),
                  child: Container(
                    padding: widget.padding,
                    color: AppColors.alpha(AppColors.card, 0.82),
                    child: widget.child,
                  ),
                ),
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
