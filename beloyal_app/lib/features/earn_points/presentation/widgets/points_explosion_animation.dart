import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PointsExplosionAnimation extends StatefulWidget {
  const PointsExplosionAnimation({
    super.key,
    required this.points,
    this.onCompleted,
  });

  final int points;
  final VoidCallback? onCompleted;

  @override
  State<PointsExplosionAnimation> createState() => _PointsExplosionAnimationState();
}

class _PointsExplosionAnimationState extends State<PointsExplosionAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _createParticles();

    _controller.forward().then((_) {
      if (mounted) widget.onCompleted?.call();
    });
  }

  void _createParticles() {
    final int count = math.min(widget.points, 50) + 20;
    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * math.pi,
        distance: _random.nextDouble() * 150 + 50,
        size: _random.nextDouble() * 8 + 4,
        color: i % 3 == 0
            ? AppColors.accent
            : (i % 3 == 1 ? AppColors.primary : AppColors.secondary),
        speed: _random.nextDouble() * 0.5 + 0.5,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ExplosionPainter(
            particles: _particles,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.speed,
  });

  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double speed;
}

class _ExplosionPainter extends CustomPainter {
  _ExplosionPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Particle> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (final particle in particles) {
      // Ease out cubic for the explosion movement
      final t = 1.0 - math.pow(1.0 - progress, 3).toDouble();
      
      // Calculate current position
      final currentDistance = particle.distance * t * particle.speed;
      final x = center.dx + math.cos(particle.angle) * currentDistance;
      final y = center.dy + math.sin(particle.angle) * currentDistance;
      
      // Gravity effect after initial burst
      final gravity = math.pow(progress, 2) * 200;
      final finalY = y + gravity;

      // Fade out
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      // Draw particle (star or circle)
      if (particle.size > 8) {
        _drawStar(canvas, Offset(x, finalY), particle.size, paint);
      } else {
        canvas.drawCircle(Offset(x, finalY), particle.size, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    final int points = 5;
    final double innerRadius = radius / 2.5;
    final double step = math.pi / points;

    for (int i = 0; i < 2 * points; i++) {
      final r = (i.isEven) ? radius : innerRadius;
      final x = center.dx + math.cos(i * step - math.pi / 2) * r;
      final y = center.dy + math.sin(i * step - math.pi / 2) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ExplosionPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
