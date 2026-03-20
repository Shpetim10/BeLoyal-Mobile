import 'dart:math' as math;
import 'package:flutter/material.dart';

class BesaLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const BesaLoader({super.key, this.size = 28.0, this.color});

  @override
  State<BesaLoader> createState() => _BesaLoaderState();
}

class _BesaLoaderState extends State<BesaLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // 1400ms duration creates a nice relaxed wave rhythm
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const int coinCount = 4;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(coinCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Stagger each coin's animation phase
            final delay = index * 0.15;
            double t = (_controller.value - delay) % 1.0;
            if (t < 0) t += 1.0;

            // Coin jumps up during the first half (t < 0.5)
            final bool isJumping = t < 0.5;

            // Map t=0..0.5 to jumpT=0..1
            final double jumpT = isJumping ? t * 2 : 0.0;

            // Height of the jump (75% of coin size)
            final double yOffset =
                isJumping ? math.sin(jumpT * math.pi) * -(widget.size * 0.75) : 0.0;

            // 3D Flip around Y-axis (two full spins while jumping)
            final double rotationY = isJumping ? jumpT * 4 * math.pi : 0.0;

            // Scale up slightly at the peak of the jump for a realistic bounce feeling
            final double scale =
                isJumping ? 1.0 + math.sin(jumpT * math.pi) * 0.15 : 1.0;

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001) // 3D perspective
                    ..rotateY(rotationY),
                  child: child,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size * 0.15),
            child: _buildPremiumCoin(),
          ),
        );
      }),
    );
  }

  Widget _buildPremiumCoin() {
    final baseColor = widget.color ?? const Color(0xFFFFD700);

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: widget.color != null
              ? [
                  baseColor.withValues(alpha: 0.8),
                  baseColor,
                  baseColor.withValues(alpha: 0.8)
                ]
              : const [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFFFD700)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4),
            blurRadius: widget.size * 0.25,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFFF8DC).withValues(alpha: 0.8),
          width: widget.size * 0.06,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.star_rounded,
          size: widget.size * 0.55,
          color: const Color(0xFFFFF8DC),
        ),
      ),
    );
  }
}
