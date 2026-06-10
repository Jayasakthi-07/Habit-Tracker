import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum GlowButtonVariant { filled, outline, ghost }

/// The primary action button of the Aurora design language: a saturated
/// indigo→violet gradient with a colored shadow, white label, hover lift and a
/// tactile press scale. Outline/ghost variants for secondary actions.
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
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final GlowButtonVariant variant;
  final bool expand;
  final Color? color;
  final EdgeInsets? padding;

  @override
  State<GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<GlowButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
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

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1.0,
          duration: AppSpacing.fast,
          curve: AppSpacing.ease,
          child: AnimatedContainer(
            duration: AppSpacing.fast,
            width: widget.expand ? double.infinity : null,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: isFilled && enabled
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _hovered
                          ? [
                              Color.lerp(fill[0], Colors.white, 0.10)!,
                              Color.lerp(fill[1], Colors.white, 0.10)!,
                            ]
                          : fill)
                  : null,
              color: switch (widget.variant) {
                GlowButtonVariant.ghost => _hovered
                    ? AppColors.alpha(accent, 0.10)
                    : Colors.transparent,
                GlowButtonVariant.outline => _hovered
                    ? AppColors.alpha(accent, 0.06)
                    : Colors.transparent,
                GlowButtonVariant.filled =>
                  enabled ? null : AppColors.alpha(AppColors.text, 0.06),
              },
              border: widget.variant == GlowButtonVariant.outline
                  ? Border.all(
                      color:
                          AppColors.alpha(accent, _hovered ? 0.85 : 0.45))
                  : null,
              boxShadow: isFilled && enabled
                  ? (custom
                      ? AppShadows.glow(accent,
                          strength: _hovered ? 0.40 : 0.30)
                      : AppShadows.accent)
                  : null,
            ),
            child: Row(
              mainAxisSize:
                  widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon,
                      size: 18, color: enabled ? fg : AppColors.faint),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: enabled ? fg : AppColors.faint,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
