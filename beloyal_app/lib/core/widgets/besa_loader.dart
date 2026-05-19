import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BesaLoader — animated bouncing loyalty coins (inline / button use)
// ─────────────────────────────────────────────────────────────────────────────

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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(coinCount, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.15;
            double t = (_controller.value - delay) % 1.0;
            if (t < 0) t += 1.0;

            final bool isJumping = t < 0.5;
            final double jumpT = isJumping ? t * 2 : 0.0;
            final double yOffset =
                isJumping ? math.sin(jumpT * math.pi) * -(widget.size * 0.75) : 0.0;
            final double rotationY = isJumping ? jumpT * 4 * math.pi : 0.0;
            final double scale =
                isJumping ? 1.0 + math.sin(jumpT * math.pi) * 0.15 : 1.0;

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Transform.scale(
                scale: scale,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
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
      ),
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
                  baseColor.withValues(alpha: 0.8),
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

// ─────────────────────────────────────────────────────────────────────────────
// BesaLoadingPage — full-page loyalty-themed loading state
// ─────────────────────────────────────────────────────────────────────────────

class BesaLoadingPage extends StatefulWidget {
  final String message;
  final bool showBackground;

  const BesaLoadingPage({
    super.key,
    this.message = 'Loading your rewards…',
    this.showBackground = true,
  });

  @override
  State<BesaLoadingPage> createState() => _BesaLoadingPageState();
}

class _BesaLoadingPageState extends State<BesaLoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _glowCtrl;
  late final AnimationController _sparkleCtrl;
  late final Animation<double> _pulseAnim;
  late final Animation<double> _glowAnim;

  final _rng = math.Random();
  final List<_SparkleParticle> _sparkles = [];

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
    _glowAnim = CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut);

    _sparkleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Generate sparkle particles
    for (int i = 0; i < 12; i++) {
      _sparkles.add(_SparkleParticle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble() * 0.6 + 0.1,
        size: _rng.nextDouble() * 6 + 3,
        phase: _rng.nextDouble(),
        speed: _rng.nextDouble() * 0.4 + 0.6,
      ));
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _glowCtrl.dispose();
    _sparkleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.showBackground
        ? Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.bgDark, Color(0xFF0F0D1A), AppColors.bgDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _buildContent(),
          )
        : _buildContent();
  }

  Widget _buildContent() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Sparkle particles
        AnimatedBuilder(
          animation: _sparkleCtrl,
          builder: (context, _) {
            return LayoutBuilder(builder: (context, constraints) {
              return Stack(
                children: _sparkles.map((s) {
                  final t = (_sparkleCtrl.value * s.speed + s.phase) % 1.0;
                  final opacity = math.sin(t * math.pi);
                  final scale = 0.5 + math.sin(t * math.pi) * 0.5;
                  return Positioned(
                    left: s.x * constraints.maxWidth,
                    top: s.y * constraints.maxHeight,
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: scale,
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: s.size,
                          color: _sparkleColor(s.phase),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            });
          },
        ),

        // Center content
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Glowing ring around coins
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (context, child) {
                final glow = 0.3 + _glowAnim.value * 0.5;
                return Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: glow * 0.25),
                        AppColors.secondary.withValues(alpha: glow * 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: child,
                );
              },
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    final scale = 0.95 + _pulseAnim.value * 0.05;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: const BesaLoader(size: 36),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Message with pulse
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, _) {
                final opacity = 0.6 + _pulseAnim.value * 0.4;
                return Opacity(
                  opacity: opacity,
                  child: Column(
                    children: [
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your loyalty rewards are being prepared',
                        textAlign: TextAlign.center,
                        style: AppTypography.dmSans(
                          fontSize: 12,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Animated coin trail dots
            AnimatedBuilder(
              animation: _glowCtrl,
              builder: (context, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final phase = (_glowCtrl.value * 3 - i) % 1.0;
                    final scale = math.sin(phase.clamp(0.0, 1.0) * math.pi);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.scale(
                        scale: 0.4 + scale * 0.6,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold.withValues(
                              alpha: (0.3 + scale * 0.7).clamp(0.0, 1.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(
                                  alpha: (scale * 0.5).clamp(0.0, 1.0),
                                ),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Color _sparkleColor(double phase) {
    final colors = [
      AppColors.gold,
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      AppColors.goldLight,
    ];
    return colors[(phase * colors.length).toInt() % colors.length];
  }
}

class _SparkleParticle {
  final double x;
  final double y;
  final double size;
  final double phase;
  final double speed;
  const _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.phase,
    required this.speed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// BesaSliver loading — sliver-compatible loading widget
// ─────────────────────────────────────────────────────────────────────────────

class BesaSliverLoading extends StatelessWidget {
  final double height;
  final String? message;

  const BesaSliverLoading({
    super.key,
    this.height = 300,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: height,
        child: BesaLoadingPage(
          message: message ?? 'Loading…',
          showBackground: false,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BesaRefreshIndicator — branded pull-to-refresh wrapper
// ─────────────────────────────────────────────────────────────────────────────

class BesaRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const BesaRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.gold,
      backgroundColor: AppColors.cardDark,
      strokeWidth: 2.5,
      displacement: 60,
      child: child,
    );
  }
}
