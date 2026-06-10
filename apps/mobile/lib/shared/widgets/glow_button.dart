import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum GlowButtonVariant { filled, outline, ghost }

/// The primary action button of the Aurora design language: a saturated
/// indigo→violet gradient with a colored shadow, white label and a tactile
/// press scale (+ light haptic). Outline/ghost variants for secondary actions.
class GlowButton extends StatefulWidget {
  const GlowButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = GlowButtonVariant.filled,
    this.expand = false,
    this.color,
    this.padding,
    this.busy = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlowButtonVariant variant;
  final bool expand;
  final Color? color;
  final EdgeInsets? padding;
  final bool busy;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final accent = widget.color ?? AppColors.primary;
    final custom = widget.color != null;
    final isFilled = widget.variant == GlowButtonVariant.filled;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    // Default fill is the brand indigo→violet; a custom color blends toward
    // violet so every filled button keeps the gradient signature.
    final fill = custom
        ? [accent, Color.lerp(accent, AppColors.fillEnd, 0.55)!]
        : const [AppColors.fillStart, AppColors.fillEnd];

    final fg = switch (widget.variant) {
      GlowButtonVariant.filled => Colors.white,
      _ => accent,
    };

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.selectionClick();
              widget.onPressed!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppSpacing.fast,
        curve: AppSpacing.ease,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          width: widget.expand ? double.infinity : null,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: isFilled && enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: fill)
                : null,
            color: switch (widget.variant) {
              GlowButtonVariant.ghost => _pressed
                  ? AppColors.alpha(accent, 0.10)
                  : Colors.transparent,
              GlowButtonVariant.outline => Colors.transparent,
              GlowButtonVariant.filled =>
                enabled ? null : AppColors.alpha(AppColors.text, 0.06),
            },
            border: widget.variant == GlowButtonVariant.outline
                ? Border.all(color: AppColors.alpha(accent, 0.45))
                : null,
            boxShadow: isFilled && enabled
                ? (custom
                    ? AppShadows.glow(accent, strength: 0.30)
                    : AppShadows.accent)
                : null,
          ),
          child: Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(fg),
                  ),
                ),
                const SizedBox(width: 10),
              ] else if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: 18, color: enabled ? fg : AppColors.faint),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: enabled ? fg : AppColors.faint,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
