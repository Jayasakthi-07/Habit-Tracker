import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../shared/widgets/window_buttons.dart';
import 'widgets/app_sidebar.dart';

/// Persistent application frame: ambient background, sidebar, custom title bar
/// and the routed page content.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _AmbientBackground(),
          Row(
            children: [
              AppSidebar(location: location),
              Expanded(
                child: Column(
                  children: [
                    _TitleBar(location: location),
                    Expanded(child: child),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Subtle radial accent glows behind everything for depth.
///
/// A solid near-black base with restrained indigo/violet/blue auras — a
/// premium "aurora" backdrop that lets the green/cyan accents pop without
/// tinting the whole canvas.
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.background,
        child: Stack(
          children: [
            // Top-left indigo aura.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.95, -1.1),
                    radius: 1.25,
                    colors: [
                      AppColors.alpha(AppColors.ambientA, 0.09),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
            // Bottom-right violet aura.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(1.15, 1.2),
                    radius: 1.15,
                    colors: [
                      AppColors.alpha(AppColors.ambientB, 0.07),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.65],
                  ),
                ),
              ),
            ),
            // Faint blue mid-glow for depth.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.3, -0.2),
                    radius: 1.4,
                    colors: [
                      AppColors.alpha(AppColors.ambientC, 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.location});
  final String location;

  String get _title {
    final seg = location.replaceAll('/', '');
    if (seg.isEmpty) return 'Dashboard';
    return seg[0].toUpperCase() + seg.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: TitleDragArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(_title,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.muted)),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
          const WindowButtons(),
        ],
      ),
    );
  }
}
