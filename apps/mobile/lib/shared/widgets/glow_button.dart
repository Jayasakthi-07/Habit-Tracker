import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum GlowButtonVariant { filled, outline, ghost }

/// A premium button with a gradient fill, subtle glow and a satisfying press
/// scale. Replaces stock [ElevatedButton] everywhere. Mobile variant: hover is
/// dropped in favour of touch press-feedback.
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
    final isFilled = widget.variant == GlowButtonVariant.filled;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    final fg = switch (widget.variant) {
      GlowButtonVariant.filled => AppColors.onPrimary,
      _ => accent,
    };

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: AppSpacing.fast,
        child: AnimatedContainer(
          duration: AppSpacing.fast,
          width: widget.expand ? double.infinity : null,
          padding: widget.padding ??
              const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: isFilled && enabled
                ? LinearGradient(colors: [accent, AppColors.secondary])
                : null,
            color: switch (widget.variant) {
              GlowButtonVariant.ghost => Colors.transparent,
              GlowButtonVariant.outline => Colors.transparent,
              GlowButtonVariant.filled =>
                enabled ? null : AppColors.alpha(Colors.white, 0.05),
            },
            border: widget.variant == GlowButtonVariant.outline
                ? Border.all(color: AppColors.alpha(accent, 0.45))
                : null,
            boxShadow: isFilled && enabled && _pressed
                ? AppShadows.glow(accent, strength: 0.20)
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
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
