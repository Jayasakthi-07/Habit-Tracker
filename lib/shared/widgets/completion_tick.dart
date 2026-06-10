import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// The premium completion indicator.
///
/// Completed: a deep, saturated gradient coin with a glassy top highlight and
/// a soft colored shadow; the white checkmark *draws itself* stroke by stroke
/// while the coin pops in with a spring and a quiet burst ring expands away.
/// Pending: a calm hairline ring.
///
/// The coin color is derived from the habit color but normalised in HSL so
/// the white check always has contrast — pale colors (mint, sky) are deepened
/// in light mode instead of washing out.
class CompletionTick extends StatefulWidget {
  const CompletionTick({
    super.key,
    required this.done,
    required this.color,
    this.size = 38,
  });

  final bool done;
  final Color color;
  final double size;

  @override
  State<CompletionTick> createState() => _CompletionTickState();
}

class _CompletionTickState extends State<CompletionTick>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    // Already-completed habits render settled — the celebration only plays on
    // the actual completion tap, never on page load or list rebuilds.
    if (widget.done) _c.value = 1;
  }

  @override
  void didUpdateWidget(CompletionTick old) {
    super.didUpdateWidget(old);
    if (widget.done && !old.done) {
      _c.forward(from: 0);
    } else if (!widget.done && old.done) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Habit color normalised for a rich coin fill in the current theme.
  Color get _base {
    final hsl = HSLColor.fromColor(widget.color);
    final light = AppColors.isLight;
    final l = light
        ? (hsl.lightness * 0.62).clamp(0.30, 0.46)
        : (hsl.lightness * 0.92).clamp(0.42, 0.60);
    final s = (hsl.saturation * 1.15).clamp(0.55, 1.0);
    return hsl
        .withLightness(l.toDouble())
        .withSaturation(s.toDouble())
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    // Self-heal: whatever the rebuild timing, a completed habit must never be
    // left with an invisible tick — skip the celebration, show the coin.
    if (widget.done && !_c.isAnimating && _c.value == 0) _c.value = 1;

    final size = widget.size;
    if (!widget.done) {
      return AnimatedContainer(
        duration: AppSpacing.fast,
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderStrong, width: 1.6),
        ),
      );
    }

    final base = _base;
    final accent = Color.lerp(base, AppColors.fillEnd, 0.55)!;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) => CustomPaint(
        size: Size.square(size),
        painter: _CoinPainter(t: _c.value, base: base, accent: accent),
      ),
    );
  }
}

class _CoinPainter extends CustomPainter {
  _CoinPainter({required this.t, required this.base, required this.accent});

  final double t;
  final Color base;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2 - 1;
    final rect = Rect.fromCircle(center: center, radius: r);

    // 1) Spring pop: scale 0 -> overshoot -> settle over the first half.
    final popT = Curves.easeOutBack.transform((t / 0.5).clamp(0.0, 1.0));

    // 3) Burst ring expands and fades over the second half (unscaled).
    final burstT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
    if (burstT > 0 && burstT < 1) {
      final eased = Curves.easeOut.transform(burstT);
      canvas.drawCircle(
        center,
        r * (1.05 + 0.50 * eased),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * (1 - eased) + 0.4
          ..color = base.withValues(alpha: 0.45 * (1 - eased)),
      );
    }

    if (popT <= 0) return;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(popT);
    canvas.translate(-center.dx, -center.dy);

    // Soft colored drop shadow grounds the coin.
    canvas.drawCircle(
      center.translate(0, r * 0.18),
      r * 0.96,
      Paint()
        ..color = base.withValues(alpha: 0.38)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // 2) The coin: rich diagonal gradient + glassy top highlight + hairline.
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [base, accent],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.35, -0.55),
          radius: 1.1,
          colors: [
            Colors.white.withValues(alpha: 0.30),
            Colors.white.withValues(alpha: 0.0),
          ],
          stops: const [0, 0.55],
        ).createShader(rect),
    );
    canvas.drawCircle(
      center,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.22),
    );

    // The checkmark draws itself stroke by stroke.
    final drawT =
        Curves.easeOutCubic.transform(((t - 0.22) / 0.5).clamp(0.0, 1.0));
    if (drawT > 0) {
      final w = size.width;
      final h = size.height;
      final check = Path()
        ..moveTo(w * 0.285, h * 0.52)
        ..lineTo(w * 0.435, h * 0.665)
        ..lineTo(w * 0.72, h * 0.36);
      final metric = check.computeMetrics().first;
      final stroke = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.088
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      // A whisper of depth under the check so it pops on pale fills too.
      canvas.drawPath(
        metric.extractPath(0, metric.length * drawT),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.088 + 1.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
      );
      canvas.drawPath(metric.extractPath(0, metric.length * drawT), stroke);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoinPainter old) =>
      old.t != t || old.base != base || old.accent != accent;
}
