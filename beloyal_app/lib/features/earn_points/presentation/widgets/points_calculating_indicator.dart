import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// A premium animated loading indicator showing orbiting coins / point-stars.
///
/// Used in the points preview card while waiting for the backend estimation
/// to return. Renders a radial orbit of 6 coin dots with a staggered fade +
/// scale pulse, producing a satisfying "calculating" feel.
class PointsCalculatingIndicator extends StatefulWidget {
  const PointsCalculatingIndicator({super.key, this.size = 80});

  final double size;

  @override
  State<PointsCalculatingIndicator> createState() =>
      _PointsCalculatingIndicatorState();
}

class _PointsCalculatingIndicatorState
    extends State<PointsCalculatingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _CoinOrbitPainter(progress: _controller.value),
          );
        },
      ),
    );
  }
}

class _CoinOrbitPainter extends CustomPainter {
  _CoinOrbitPainter({required this.progress});

  final double progress;

  static const int _dotCount = 8;
  static const double _trailFactor = 0.55; // how long the trail fades

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 6;

    for (int i = 0; i < _dotCount; i++) {
      final fraction = i / _dotCount;
      // Each dot has a phase offset. The "lead" dot is at the current progress.
      final phase = (progress - fraction) % 1.0;

      // Trail opacity: head = 1.0, tail fades to 0
      final opacity = (phase < _trailFactor
              ? phase / _trailFactor
              : (1.0 - phase) / (1.0 - _trailFactor))
          .clamp(0.0, 1.0);

      // Trail size: head dots are larger
      final dotRadius = 3.5 + 4.0 * (phase < _trailFactor
          ? phase / _trailFactor
          : (1.0 - phase) / (1.0 - _trailFactor)).clamp(0.0, 1.0);

      final angle = 2 * math.pi * fraction + 2 * math.pi * progress;
      final dx = center.dx + outerRadius * math.cos(angle);
      final dy = center.dy + outerRadius * math.sin(angle);

      // Outer glow
      final glowPaint = Paint()
        ..color = AppColors.accent.withValues(alpha: opacity * 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(Offset(dx, dy), dotRadius + 3, glowPaint);

      // Coin dot — gradient from gold to accent
      final coinPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            Color.lerp(AppColors.accent, const Color(0xFFFFD700), 0.5)!
                .withValues(alpha: opacity),
            AppColors.accent.withValues(alpha: opacity * 0.5),
          ],
        ).createShader(Rect.fromCircle(center: Offset(dx, dy), radius: dotRadius));
      canvas.drawCircle(Offset(dx, dy), dotRadius, coinPaint);
    }

    // Centre "pts" text
    final textStyle = TextStyle(
      color: AppColors.accent.withValues(alpha: 0.8),
      fontSize: size.width * 0.16,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.5,
    );
    final textPainter = TextPainter(
      text: TextSpan(text: 'pts', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_CoinOrbitPainter old) => old.progress != progress;
}
