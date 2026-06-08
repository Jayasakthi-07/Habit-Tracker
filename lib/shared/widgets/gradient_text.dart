import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Renders text with a gradient fill, used for headline accents.
class GradientText extends StatelessWidget {
  const GradientText(this.text, {super.key, this.style, this.gradient, this.textAlign});

  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) =>
          (gradient ?? AppColors.primaryGradient).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: (style ?? const TextStyle()).copyWith(color: Colors.white),
      ),
    );
  }
}
