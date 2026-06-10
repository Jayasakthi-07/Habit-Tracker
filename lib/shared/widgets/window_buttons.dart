import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/theme/app_colors.dart';
import '../../core/window/window_service.dart';

/// Custom minimize / maximize / close controls for the frameless window.
class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WinButton(
          icon: Icons.remove_rounded,
          tooltip: 'Minimize',
          onTap: WindowService.minimize,
        ),
        _WinButton(
          icon: Icons.crop_square_rounded,
          tooltip: 'Maximize',
          onTap: WindowService.maximizeToggle,
        ),
        _WinButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          hoverColor: AppColors.danger,
          onTap: WindowService.close,
        ),
      ],
    );
  }
}

class _WinButton extends StatefulWidget {
  const _WinButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? hoverColor;

  @override
  State<_WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<_WinButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 46,
            height: 36,
            color: _hover
                ? (widget.hoverColor ?? AppColors.alpha(AppColors.text, 0.08))
                : Colors.transparent,
            child: Icon(
              widget.icon,
              size: 16,
              color: _hover && widget.hoverColor != null ? Colors.white : AppColors.muted,
            ),
          ),
        ),
      ),
    );
  }
}

/// A draggable region that moves the window when dragged.
class TitleDragArea extends StatelessWidget {
  const TitleDragArea({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) => windowManager.startDragging(),
      onDoubleTap: WindowService.maximizeToggle,
      child: child,
    );
  }
}
