import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

enum GlowButtonVariant { filled, outline, ghost }

/// A premium button with a gradient fill, animated glow on hover and a
/// satisfying press scale. Replaces stock [ElevatedButton] everywhere.
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
    final isFilled = widget.variant == GlowButtonVariant.filled;
    final radius = BorderRadius.circular(AppSpacing.radiusMd);

    final fg = switch (widget.variant) {
      GlowButtonVariant.filled => const Color(0xFF002417),
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
          scale: _pressed ? 0.96 : 1.0,
          duration: AppSpacing.fast,
          child: AnimatedContainer(
            duration: AppSpacing.fast,
            width: widget.expand ? double.infinity : null,
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: isFilled
                  ? LinearGradient(colors: [accent, AppColors.secondary])
                  : null,
              color: switch (widget.variant) {
                GlowButtonVariant.ghost =>
                  _hovered ? AppColors.alpha(accent, 0.10) : Colors.transparent,
                GlowButtonVariant.outline => Colors.transparent,
                GlowButtonVariant.filled => null,
              },
              border: widget.variant == GlowButtonVariant.outline
                  ? Border.all(color: AppColors.alpha(accent, _hovered ? 0.9 : 0.45))
                  : null,
              boxShadow: isFilled && enabled && _hovered
                  ? AppShadows.glow(accent, strength: 0.22)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: enabled ? fg : AppColors.faint),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    color: enabled ? fg : AppColors.faint,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
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
