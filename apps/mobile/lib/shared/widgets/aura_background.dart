import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// The signature ambient backdrop: a deep base with two or three soft aurora
/// blobs (indigo / violet / sky) drifting in the corners. Pure gradients — no
/// BackdropFilter — so it costs almost nothing to render.
class AuraBackground extends StatelessWidget {
  const AuraBackground({super.key, required this.child, this.intensity = 1});

  final Widget child;

  /// Scales blob opacity; secondary screens can pass < 1 for a quieter wash.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    final light = AppColors.isLight;
    final a = (light ? 0.10 : 0.16) * intensity;
    final b = (light ? 0.08 : 0.13) * intensity;
    final c = (light ? 0.05 : 0.08) * intensity;

    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            left: -100,
            child: _blob(AppColors.ambientA, 420, a),
          ),
          Positioned(
            top: -80,
            right: -120,
            child: _blob(AppColors.ambientB, 380, b),
          ),
          Positioned(
            bottom: -160,
            right: -60,
            child: _blob(AppColors.ambientC, 440, c),
          ),
          child,
        ],
      ),
    );
  }

  Widget _blob(Color color, double size, double alpha) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.alpha(color, alpha),
              AppColors.alpha(color, 0),
            ],
          ),
        ),
      ),
    );
  }
}
