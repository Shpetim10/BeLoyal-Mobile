import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/customer_profile_creation_response.dart';
import '../widgets/premium_loyalty_card.dart';

class LoyaltyCardRevealPage extends ConsumerStatefulWidget {
  const LoyaltyCardRevealPage({super.key, required this.response});
  final CustomerProfileCreationResponse response;

  @override
  ConsumerState<LoyaltyCardRevealPage> createState() =>
      _LoyaltyCardRevealPageState();
}

enum _Stage { envelope, opening, cardReveal, continue_, flyOut }

class _LoyaltyCardRevealPageState extends ConsumerState<LoyaltyCardRevealPage>
    with TickerProviderStateMixin {
  _Stage _stage = _Stage.envelope;
  late final AnimationController _flyCtrl;
  late final Animation<double> _flyScale;
  late final Animation<Offset> _flySlide;
  late final Animation<double> _flyFade;
  late final AnimationController _ctaCtrl;
  late final Animation<double> _ctaFade;
  late final ConfettiController _confetti;
  late final AnimationController _particleCtrl;
  late final AnimationController _bloomCtrl;
  late final Animation<double> _bloomOpacity;
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringRadius;
  late final Animation<double> _ringOpacity;
  late final AnimationController _buttonPulseCtrl;
  late final Animation<double> _buttonGlow;

  @override
  void initState() {
    super.initState();

    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ctaFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeIn));

    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flyScale = Tween<double>(
      begin: 1,
      end: 0.08,
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeInCubic));
    _flySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 3.0),
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeInQuart));
    _flyFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _flyCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    _confetti = ConfettiController(duration: const Duration(seconds: 2));

    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _bloomCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bloomOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.75), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0), weight: 75),
    ]).animate(CurvedAnimation(parent: _bloomCtrl, curve: Curves.easeOut));

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ringRadius = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOutCubic));
    _ringOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _buttonPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _buttonGlow = Tween<double>(begin: 0.28, end: 0.62).animate(
      CurvedAnimation(parent: _buttonPulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctaCtrl.dispose();
    _flyCtrl.dispose();
    _confetti.dispose();
    _particleCtrl.dispose();
    _bloomCtrl.dispose();
    _ringCtrl.dispose();
    _buttonPulseCtrl.dispose();
    super.dispose();
  }

  void _onRevealComplete() {
    if (!mounted) return;
    setState(() => _stage = _Stage.continue_);
    _ctaCtrl.forward();
    _bloomCtrl.forward(from: 0);
    _ringCtrl.forward(from: 0);
  }

  Future<void> _onContinue() async {
    if (_stage != _Stage.continue_) return;
    setState(() => _stage = _Stage.flyOut);
    _flyCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    context.go('/customer/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          _RichBackground(controller: _particleCtrl, size: size),

          // Golden bloom flash on card reveal
          AnimatedBuilder(
            animation: _bloomOpacity,
            builder: (_, __) {
              final opacity = _bloomOpacity.value;
              if (opacity < 0.01) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _BloomPainter(opacity: opacity)),
                ),
              );
            },
          ),

          // Expanding ring pulse on card reveal
          AnimatedBuilder(
            animation: Listenable.merge([_ringRadius, _ringOpacity]),
            builder: (_, __) {
              final radius = _ringRadius.value;
              final opacity = _ringOpacity.value;
              if (opacity < 0.01) return const SizedBox.shrink();
              return Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RingPulsePainter(
                      radius: radius,
                      opacity: opacity,
                    ),
                  ),
                ),
              );
            },
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              gravity: 0.3,
              emissionFrequency: 0.06,
              colors: const [
                AppColors.accent,
                Color(0xFFF97316),
                Color(0xFF7C3AED),
                Colors.white,
                Color(0xFF06B6D4),
              ],
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildHeader(),
                    const Spacer(),
                    _buildCenterContent(size, constraints.maxHeight),
                    const Spacer(),
                    _buildCta(),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final showCardTitle =
        _stage == _Stage.cardReveal ||
        _stage == _Stage.continue_ ||
        _stage == _Stage.flyOut;

    return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              AnimatedSwitcher(
                duration: 400.ms,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, -0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: showCardTitle
                    ? ShaderMask(
                        key: const ValueKey('card'),
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFFE57F),
                            Color(0xFFFFD700),
                            Color(0xFFFFA500),
                            Color(0xFFFFD700),
                          ],
                          stops: [0.0, 0.35, 0.65, 1.0],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: const Text(
                          '✨ Your Loyalty Card',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : Column(
                        key: const ValueKey('envelope'),
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent.withValues(alpha: 0.2),
                                  const Color(
                                    0xFF7C3AED,
                                  ).withValues(alpha: 0.2),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '🎁  A special delivery for you',
                              style: TextStyle(
                                color: AppColors.accent.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Your Loyalty Card\nHas Arrived',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 4),
              AnimatedOpacity(
                duration: 400.ms,
                opacity: (_stage == _Stage.envelope || _stage == _Stage.opening)
                    ? 1.0
                    : 0.0,
                child: Text(
                  'Tap the envelope to reveal your card',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 700.ms)
        .slideY(begin: -0.15, end: 0, duration: 700.ms);
  }

  Widget _buildCenterContent(Size size, double availableHeight) {
    final safeHeight = availableHeight - 400;
    final cardWidth = math
        .min(size.width - 64, safeHeight / 1.55)
        .clamp(0.0, 380.0);
    final showCard =
        _stage == _Stage.cardReveal ||
        _stage == _Stage.continue_ ||
        _stage == _Stage.flyOut;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (!showCard || _stage == _Stage.cardReveal)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _stage == _Stage.cardReveal ? 0.0 : 1.0,
              child: BesaEnvelopeReveal(
                width: cardWidth,
                card: PremiumLoyaltyCard(
                  firstName: widget.response.firstName,
                  lastName: widget.response.lastName,
                  qrToken: widget.response.qrToken,
                  manualCode: widget.response.manualCode,
                ),
                onTap: () {
                  if (_stage != _Stage.envelope) return;
                  setState(() => _stage = _Stage.opening);
                },
                onRevealComplete: () {
                  _confetti.play();
                  setState(() => _stage = _Stage.cardReveal);
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) _onRevealComplete();
                  });
                },
              ),
            ),
          if (showCard)
            AnimatedBuilder(
              animation: Listenable.merge([_flyScale, _flySlide, _flyFade]),
              builder: (context, child) {
                final scale = _stage == _Stage.flyOut ? _flyScale.value : 1.0;
                final slideVal = _stage == _Stage.flyOut
                    ? _flySlide.value
                    : Offset.zero;
                final fadeVal = _stage == _Stage.flyOut ? _flyFade.value : 1.0;

                return FadeTransition(
                  opacity: AlwaysStoppedAnimation(fadeVal),
                  child: Transform.translate(
                    offset: Offset(0, slideVal.dy * size.height * 0.3),
                    child: Transform.scale(scale: scale, child: child),
                  ),
                );
              },
              child: SizedBox(
                width: cardWidth * 0.92,
                child: PremiumLoyaltyCard(
                  firstName: widget.response.firstName,
                  lastName: widget.response.lastName,
                  qrToken: widget.response.qrToken,
                  manualCode: widget.response.manualCode,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCta() {
    final firstName = widget.response.firstName;
    return AnimatedBuilder(
      animation: Listenable.merge([_ctaFade, _buttonGlow]),
      builder: (context, _) {
        final t = _ctaFade.value;
        final glowAlpha = _buttonGlow.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 40),
            child: Transform.scale(
              scale: 0.90 + t * 0.10,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    // Celebration badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                        border: Border.all(
                          color: const Color(
                            0xFFFFD700,
                          ).withValues(alpha: 0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🎉', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'Welcome aboard, $firstName!',
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Your rewards journey begins now.\nStart earning at your favourite spots.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.75),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Pulsing glow button
                    SizedBox(
                      width: double.infinity,
                      child: GestureDetector(
                        onTap: _onContinue,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: const LinearGradient(
                              colors: [AppColors.accent, Color(0xFFF97316)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(
                                  alpha: glowAlpha,
                                ),
                                blurRadius: 28,
                                spreadRadius: 0,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: const Color(
                                  0xFFF97316,
                                ).withValues(alpha: glowAlpha * 0.5),
                                blurRadius: 48,
                                spreadRadius: 4,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Stack(
                              children: [
                                // Shimmer sweep
                                Positioned.fill(
                                  child: _ShimmerSweep(
                                    controller: _buttonPulseCtrl,
                                  ),
                                ),
                                const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Go to My Dashboard',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Subtle diagonal shimmer sweep that travels across the button.
class _ShimmerSweep extends StatelessWidget {
  const _ShimmerSweep({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return CustomPaint(painter: _ShimmerPainter(progress: t));
      },
    );
  }
}

class _ShimmerPainter extends CustomPainter {
  const _ShimmerPainter({required this.progress});
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    // Sweep from -20% to 120% of width
    final x = size.width * (-0.2 + progress * 1.4);
    final band = size.width * 0.18;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.0),
          Colors.white.withValues(alpha: 0.18),
          Colors.white.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(math.pi / 5),
      ).createShader(Rect.fromLTWH(x - band, 0, band * 2, size.height));
    canvas.drawRect(Rect.fromLTWH(x - band, 0, band * 2, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

class BesaEnvelopeReveal extends StatefulWidget {
  const BesaEnvelopeReveal({
    super.key,
    required this.width,
    required this.card,
    required this.onTap,
    required this.onRevealComplete,
  });

  final double width;
  final Widget card;
  final VoidCallback onTap;
  final VoidCallback onRevealComplete;

  @override
  State<BesaEnvelopeReveal> createState() => _BesaEnvelopeRevealState();
}

class _BesaEnvelopeRevealState extends State<BesaEnvelopeReveal>
    with TickerProviderStateMixin {
  late final AnimationController _master;
  late final AnimationController _breatheCtrl;
  late final Animation<double> _breatheScale;
  late final Animation<double> _sealSquish; // Act 2: 10%–18% (squish down)
  late final Animation<double> _sealBurst; // Act 2: 18%–30% (burst out)
  late final Animation<double> _sealFade; // Act 2: 15%–30% (fade)
  late final Animation<double> _particleProg; // Act 2: 10%–35% (gold particles)
  late final Animation<double> _flapAngle; // Act 3: 20%–60% (flap flip)
  late final Animation<double> _cardSlideY; // Act 4: 40%–100% (card rises)
  late final Animation<double> _cardScale; // Act 4: 40%–100% (card grows)
  late final Animation<double> _cardTiltX; // Act 4: 40%–85% (3D tilt)
  late final Animation<double> _dimOverlay; // Act 4: 50%–100% (bg dims)

  bool _opened = false;

  // Seeded RNG for consistent gold burst particles across frames
  final _rng = math.Random(42);
  late final List<_GoldParticle> _particles;

  @override
  void initState() {
    super.initState();
    _breatheCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _breatheScale = Tween<double>(
      begin: 1.0,
      end: 1.025,
    ).animate(CurvedAnimation(parent: _breatheCtrl, curve: Curves.easeInOut));
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // Act 2 — Seal break
    _sealSquish = Tween<double>(begin: 1.0, end: 0.75).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.10, 0.18, curve: Curves.easeInBack),
      ),
    );
    _sealBurst = Tween<double>(begin: 0.75, end: 1.5).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.18, 0.32, curve: Curves.easeOutCubic),
      ),
    );
    _sealFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.16, 0.32, curve: Curves.easeOut),
      ),
    );
    _particleProg = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.12, 0.40, curve: Curves.easeOut),
      ),
    );

    // Act 3 — Flap opens
    _flapAngle = Tween<double>(begin: 0.0, end: -math.pi).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.22, 0.62, curve: Curves.elasticOut),
      ),
    );

    // Act 4 — Card rises
    _cardSlideY = Tween<double>(begin: 0.45, end: 0.055).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.42, 1.0, curve: Curves.easeOutQuart),
      ),
    );
    _cardScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.42, 0.95, curve: Curves.easeOutCubic),
      ),
    );
    _cardTiltX = Tween<double>(begin: 0.12, end: 0.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.42, 0.85, curve: Curves.easeOutCubic),
      ),
    );
    _dimOverlay = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.50, 1.0, curve: Curves.easeIn),
      ),
    );

    // Pre-generate gold burst particles
    _particles = List.generate(22, (_) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final speed = 0.4 + _rng.nextDouble() * 0.6;
      final size = 1.5 + _rng.nextDouble() * 3.0;
      final hue = _rng.nextBool() ? 45.0 : 35.0; // gold / amber
      return _GoldParticle(angle: angle, speed: speed, size: size, hue: hue);
    });

    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onRevealComplete();
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _breatheCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (_opened) return;
    _opened = true;
    _breatheCtrl.stop();
    widget.onTap();
    _master.forward();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width;
    final h = w * 1.55;
    final flapHeight = h * 0.52;
    final sealSize = w * 0.22;
    final sealTop = flapHeight - (sealSize / 2);

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breatheCtrl, _master]),
        builder: (context, _) {
          final breatheScale = _opened ? 1.0 : _breatheScale.value;

          final flapWidget = Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Transform(
              alignment: Alignment.topCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateX(_flapAngle.value),
              child: CustomPaint(
                size: Size(w, flapHeight),
                painter: _FlapPainter(),
              ),
            ),
          );

          return Transform.scale(
            scale: breatheScale,
            child: SizedBox(
              width: w,
              height: h,
              child: ClipRect(
                clipper: _EnvelopeBottomClipper(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Z-0:
                    Positioned.fill(
                      child: _EnvelopeBack(width: w, height: h),
                    ),

                    // Z-1:
                    if (_flapAngle.value <= -math.pi / 2) flapWidget,

                    // Z-2:
                    Positioned(
                      left: w * 0.04,
                      right: w * 0.04,
                      top: h * _cardSlideY.value,
                      child: Transform.scale(
                        scale: _cardScale.value,
                        child: Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..rotateX(_cardTiltX.value),
                          child: widget.card,
                        ),
                      ),
                    ),

                    // Z-3:
                    Positioned.fill(
                      child: CustomPaint(painter: _FrontPocketPainter()),
                    ),

                    // Z-3.5: dim overlay — fades envelope as card rises to the spotlight
                    if (_dimOverlay.value > 0.01)
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            color: Colors.black.withValues(
                              alpha: _dimOverlay.value,
                            ),
                          ),
                        ),
                      ),

                    // Z-4:
                    if (_flapAngle.value > -math.pi / 2) flapWidget,

                    // Z-5:
                    if (_particleProg.value > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: h * 0.28,
                        height: h * 0.3,
                        child: CustomPaint(
                          painter: _GoldBurstPainter(
                            progress: _particleProg.value,
                            particles: _particles,
                          ),
                        ),
                      ),

                    // Z-6:
                    if (_sealFade.value > 0.01)
                      Positioned(
                        top: sealTop,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Opacity(
                            opacity: _sealFade.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _master.value < 0.18
                                  ? _sealSquish.value
                                  : _sealBurst.value,
                              child: Image.asset(
                                'assets/images/envelope_wax_seal.png',
                                width: sealSize,
                                height: sealSize,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GoldParticle {
  final double angle;
  final double speed;
  final double size;
  final double hue;
  const _GoldParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.hue,
  });
}

class _GoldBurstPainter extends CustomPainter {
  const _GoldBurstPainter({required this.progress, required this.particles});
  final double progress;
  final List<_GoldParticle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = size.width * 0.45;

    for (final p in particles) {
      final dist = maxRadius * p.speed * progress;
      final x = cx + math.cos(p.angle) * dist;
      final y = cy + math.sin(p.angle) * dist;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final r = p.size * (1.0 - progress * 0.5);

      final paint = Paint()
        ..color = HSLColor.fromAHSL(opacity, p.hue, 0.9, 0.55).toColor()
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);

      // Tiny sparkle glow around each particle
      final glowPaint = Paint()
        ..color = HSLColor.fromAHSL(opacity * 0.3, p.hue, 1.0, 0.7).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(x, y), r * 2.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_GoldBurstPainter old) => old.progress != progress;
}

class _EnvelopeBack extends StatelessWidget {
  const _EnvelopeBack({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF081428), Color(0xFF060E1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.08),
            blurRadius: 40,
            spreadRadius: 2,
          ),
        ],
      ),
      // Inner depth shadow via a gradient overlay
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FrontPocketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final startY = h * 0.42;

    final pocketPath = Path()
      ..moveTo(0, startY)
      ..lineTo(w / 2, startY + 25)
      ..lineTo(w, startY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final paint = Paint()..color = const Color(0xFF0A1628);
    canvas.drawPath(pocketPath, paint);

    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final openingPath = Path()
      ..moveTo(0, startY)
      ..lineTo(w / 2, startY + 25)
      ..lineTo(w, startY);
    canvas.drawPath(openingPath, goldPaint);

    final diagonals = Path()
      ..moveTo(0, h)
      ..lineTo(w / 2, startY + 25)
      ..lineTo(w, h);
    canvas.drawPath(
      diagonals,
      Paint()
        ..color = const Color(0xFFD4AF37).withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke,
    );

    final edgePath = Path()
      ..moveTo(0, startY)
      ..lineTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w, startY);
    canvas.drawPath(edgePath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final flapPath = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h)
      ..lineTo(w, 0)
      ..close();

    final flapPaint = Paint()..color = const Color(0xFF0A1628);

    canvas.drawShadow(flapPath, Colors.black87, 10, true);

    canvas.drawPath(flapPath, flapPaint);

    final goldPaint = Paint()
      ..color = const Color(0xFFD4AF37).withValues(alpha: 0.8)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawPath(flapPath, goldPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RichBackground extends StatelessWidget {
  const _RichBackground({required this.controller, required this.size});
  final AnimationController controller;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        size: size,
        painter: _BackgroundPainter(progress: controller.value),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  const _BackgroundPainter({required this.progress});
  final double progress;

  static const _particles = [
    (0.15, 0.2, 3.0, 0.0),
    (0.78, 0.12, 2.0, 0.2),
    (0.55, 0.35, 4.0, 0.5),
    (0.25, 0.65, 2.5, 0.1),
    (0.88, 0.5, 3.5, 0.7),
    (0.42, 0.8, 2.0, 0.4),
    (0.62, 0.22, 1.5, 0.9),
    (0.08, 0.45, 3.0, 0.3),
    (0.93, 0.75, 2.0, 0.6),
    (0.35, 0.92, 2.5, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint();
    bgPaint.shader = const LinearGradient(
      colors: [Color(0xFF050D1A), Color(0xFF0A0520), Color(0xFF070F1C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    _drawOrb(
      canvas,
      size,
      cx: 0.85,
      cy: 0.12,
      radius: 0.35,
      color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
    );
    _drawOrb(
      canvas,
      size,
      cx: 0.1,
      cy: 0.85,
      radius: 0.3,
      color: AppColors.accent.withValues(alpha: 0.07),
    );
    _drawOrb(
      canvas,
      size,
      cx: 0.5,
      cy: 0.5,
      radius: 0.5,
      color: const Color(0xFF1E3A6E).withValues(alpha: 0.15),
    );

    final particlePaint = Paint()..style = PaintingStyle.fill;
    for (final (px, py, radius, phase) in _particles) {
      final floatY = math.sin((progress + phase) * math.pi * 2) * 8;
      final opacity = (math.sin((progress + phase) * math.pi * 2) + 1) / 2;

      particlePaint.color = AppColors.accent.withValues(alpha: 0.4 * opacity);
      canvas.drawCircle(
        Offset(px * size.width, py * size.height + floatY),
        radius,
        particlePaint,
      );

      if (radius > 2.7) {
        final crossPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.25 * opacity)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke;
        final x = px * size.width;
        final y = py * size.height + floatY;
        canvas.drawLine(
          Offset(x - radius * 2, y),
          Offset(x + radius * 2, y),
          crossPaint,
        );
        canvas.drawLine(
          Offset(x, y - radius * 2),
          Offset(x, y + radius * 2),
          crossPaint,
        );
      }
    }

    final streakPaint = Paint();
    streakPaint.shader = LinearGradient(
      colors: [
        Colors.transparent,
        AppColors.accent.withValues(alpha: 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, size.height * 0.4, size.width, 2));
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width, 1),
      streakPaint,
    );
  }

  void _drawOrb(
    Canvas canvas,
    Size size, {
    required double cx,
    required double cy,
    required double radius,
    required Color color,
  }) {
    final paint = Paint();
    paint.shader = RadialGradient(colors: [color, Colors.transparent])
        .createShader(
          Rect.fromCircle(
            center: Offset(cx * size.width, cy * size.height),
            radius: radius * size.width,
          ),
        );
    canvas.drawCircle(
      Offset(cx * size.width, cy * size.height),
      radius * size.width,
      paint,
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) => old.progress != progress;
}

class _EnvelopeBottomClipper extends CustomClipper<Rect> {
  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(-1000, -1000, size.width + 1000, size.height);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

/// Golden bloom that flashes across the screen the instant the card is revealed.
class _BloomPainter extends CustomPainter {
  const _BloomPainter({required this.opacity});
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              const Color(0xFFFFD700).withValues(alpha: opacity * 0.55),
              const Color(0xFFFFA500).withValues(alpha: opacity * 0.25),
              Colors.transparent,
            ],
            stops: const [0.0, 0.45, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: size.width * 0.75),
          );
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_BloomPainter old) => old.opacity != opacity;
}

/// Expanding ring pulse that radiates outward when the card appears.
class _RingPulsePainter extends CustomPainter {
  const _RingPulsePainter({required this.radius, required this.opacity});
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxRadius = size.width * 0.65;

    for (int i = 0; i < 3; i++) {
      final lag = i * 0.18;
      final r = ((radius - lag).clamp(0.0, 1.0)) * maxRadius;
      if (r <= 0) continue;
      final alpha = ((opacity - lag * 0.5).clamp(0.0, 1.0));

      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 - i * 0.6
        ..color = const Color(
          0xFFD4AF37,
        ).withValues(alpha: alpha * (1 - i * 0.28));
      canvas.drawCircle(Offset(cx, cy), r, ringPaint);
    }
  }

  @override
  bool shouldRepaint(_RingPulsePainter old) =>
      old.radius != radius || old.opacity != opacity;
}
