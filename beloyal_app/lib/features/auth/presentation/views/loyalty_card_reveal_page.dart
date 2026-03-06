import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/customer_profile_creation_response.dart';
import '../widgets/premium_loyalty_card.dart';

/// Reveals the user's new loyalty card through a premium, cinematic animation:
///
///  Stage 0 – [_Stage.envelope]   : Premium glowing envelope, tap-to-open prompt
///  Stage 1 – [_Stage.opening]    : Envelope flap rotates open (300 ms)
///  Stage 2 – [_Stage.cardReveal] : Confetti burst + card slides up
///  Stage 3 – [_Stage.continue_]  : Continue button visible, tap triggers exit
///  Stage 4 – [_Stage.flyOut]     : Card shrinks and flies toward nav centre
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
  // ── Stage ──
  _Stage _stage = _Stage.envelope;

  // ── Envelope glow pulse ──
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // ── Envelope flap open ──
  late final AnimationController _flapCtrl;
  late final Animation<double> _flapAnim;

  // ── Card slide-up ──
  late final AnimationController _cardCtrl;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _cardFade;
  late final Animation<double> _envelopeFade;

  // ── Card fly-out to navbar ──
  late final AnimationController _flyCtrl;
  late final Animation<double> _flyScale;
  late final Animation<Offset> _flySlide;
  late final Animation<double> _flyFade;

  // ── Continue button ──
  late final AnimationController _ctaCtrl;
  late final Animation<double> _ctaFade;

  // ── Particles ──
  late final ConfettiController _confetti;

  // ── Background particle animation ──
  late final AnimationController _particleCtrl;

  @override
  void initState() {
    super.initState();

    // Glow pulse — continuous
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Envelope flap
    _flapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flapAnim = Tween<double>(
      begin: 0,
      end: math.pi,
    ).animate(CurvedAnimation(parent: _flapCtrl, curve: Curves.easeOut));

    // Card reveal
    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );
    _envelopeFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0, 0.4, curve: Curves.easeOut),
      ),
    );

    // Continue button
    _ctaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _ctaFade = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctaCtrl, curve: Curves.easeIn));

    // Fly-out to navbar
    _flyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _flyScale = Tween<double>(
      begin: 1,
      end: 0.08,
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeInCubic));
    _flySlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 3.0), // flies down toward nav bar
    ).animate(CurvedAnimation(parent: _flyCtrl, curve: Curves.easeInQuart));
    _flyFade = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _flyCtrl,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Confetti
    _confetti = ConfettiController(duration: const Duration(seconds: 2));

    // Background particles
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    _flapCtrl.dispose();
    _cardCtrl.dispose();
    _ctaCtrl.dispose();
    _flyCtrl.dispose();
    _confetti.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  // ─── Interaction handlers ─────────────────────────────────────────────────

  Future<void> _onEnvelopeTap() async {
    if (_stage != _Stage.envelope) return;
    setState(() => _stage = _Stage.opening);
    _glowCtrl.stop();

    await _flapCtrl.forward();
    setState(() => _stage = _Stage.cardReveal);
    _confetti.play();
    await _cardCtrl.forward();

    setState(() => _stage = _Stage.continue_);
    _ctaCtrl.forward();
  }

  Future<void> _onContinue() async {
    if (_stage != _Stage.continue_) return;
    setState(() => _stage = _Stage.flyOut);
    await _flyCtrl.forward();
    if (!mounted) return;
    context.go('/customer/dashboard');
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Rich dark background ──
          _RichBackground(controller: _particleCtrl, size: size),

          // ── Confetti ──
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

          // ── Main content ──
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                // Header text
                _buildHeader(),
                const Spacer(),
                // Envelope / Card area
                _buildCenterContent(size),
                const Spacer(),
                // CTA
                _buildCta(),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

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
                child: showCardTitle
                    ? Text(
                        key: const ValueKey('card'),
                        '✨ Your Loyalty Card',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      )
                    : Text(
                        key: const ValueKey('envelope'),
                        'Your Loyalty Card\nHas Arrived',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
              const SizedBox(height: 10),
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

  // ── Centre content (envelope or card) ──────────────────────────────────────

  Widget _buildCenterContent(Size size) {
    final cardWidth = (size.width - 64).clamp(0.0, 380.0);
    final showCard = _stage != _Stage.envelope && _stage != _Stage.opening;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Envelope (fades out during card reveal) ──
          if (!showCard || _stage == _Stage.cardReveal)
            AnimatedBuilder(
              animation: Listenable.merge([_flapAnim, _envelopeFade]),
              builder: (context, _) {
                final envelopeOpacity = showCard ? _envelopeFade.value : 1.0;
                return Opacity(
                  opacity: envelopeOpacity,
                  child: GestureDetector(
                    onTap: _onEnvelopeTap,
                    child: _PremiumEnvelope(
                      glowAnim: _glowAnim,
                      flapAngle: _flapAnim.value,
                      width: cardWidth,
                    ),
                  ),
                );
              },
            ),

          // ── Loyalty card (slides up) ──
          if (showCard)
            AnimatedBuilder(
              animation: Listenable.merge([
                _cardFade,
                _flyScale,
                _flySlide,
                _flyFade,
              ]),
              builder: (context, child) {
                final fadeVal = _stage == _Stage.flyOut
                    ? _flyFade.value
                    : _cardFade.value;
                final scale = _stage == _Stage.flyOut ? _flyScale.value : 1.0;
                final slideVal = _stage == _Stage.flyOut
                    ? _flySlide.value
                    : Offset.zero;

                return FadeTransition(
                  opacity: AlwaysStoppedAnimation(fadeVal),
                  child: SlideTransition(
                    position: _stage == _Stage.cardReveal
                        ? _cardSlide
                        : AlwaysStoppedAnimation(Offset.zero),
                    child: Transform.translate(
                      offset: Offset(0, slideVal.dy * size.height * 0.3),
                      child: Transform.scale(scale: scale, child: child),
                    ),
                  ),
                );
              },
              child: PremiumLoyaltyCard(
                firstName: widget.response.firstName,
                lastName: widget.response.lastName,
                qrToken: widget.response.qrToken,
                manualCode: widget.response.manualCode,
              ),
            ),
        ],
      ),
    );
  }

  // ── Continue CTA ──────────────────────────────────────────────────────────

  Widget _buildCta() {
    return AnimatedBuilder(
      animation: _ctaFade,
      builder: (context, _) {
        return Opacity(
          opacity: _ctaFade.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  'Your rewards journey begins now',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GestureDetector(
                    onTap: _onContinue,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, Color(0xFFF97316)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Go to My Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Rich background with subtle animated particles ───────────────────────────

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
    // Deep rich background gradient
    final bgPaint = Paint();
    bgPaint.shader = const LinearGradient(
      colors: [
        Color(0xFF050D1A), // Very deep navy
        Color(0xFF0A0520), // Deep purple-black
        Color(0xFF070F1C), // Rich midnight
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Large ambient orbs
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

    // Floating sparkle particles
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

      // Subtle star sparkle cross
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

    // Very subtle gold horizontal streak in the middle area
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

// ─── Premium envelope widget ──────────────────────────────────────────────────

class _PremiumEnvelope extends StatelessWidget {
  const _PremiumEnvelope({
    required this.glowAnim,
    required this.flapAngle,
    required this.width,
  });

  final Animation<double> glowAnim;
  final double flapAngle;
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.7; // envelope proportions

    return AnimatedBuilder(
      animation: glowAnim,
      builder: (_, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1040), Color(0xFF0D1B3E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(
                  alpha: 0.25 * glowAnim.value,
                ),
                blurRadius: 50 * glowAnim.value,
                spreadRadius: 4 * glowAnim.value,
              ),
              // Soft warm ambient glow
              BoxShadow(
                color: const Color(
                  0xFFFBBF24,
                ).withValues(alpha: 0.15 * glowAnim.value),
                blurRadius: 30,
                spreadRadius: -4,
              ),
              // Crisp depth shadow
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Envelope body ──
            _EnvelopeBody(width: width, height: height),

            // ── Animated flap ──
            Align(
              alignment: Alignment.topCenter,
              child: Transform(
                alignment: Alignment.topCenter,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(flapAngle),
                child: _EnvelopeFlap(width: width),
              ),
            ),

            // ── Inner glow (from inside before opening) ──
            if (flapAngle < 0.3)
              Positioned(
                bottom: height * 0.1,
                left: width * 0.2,
                right: width * 0.2,
                child: AnimatedBuilder(
                  animation: glowAnim,
                  builder: (_, __) => Container(
                    height: height * 0.18,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(
                            alpha: 0.5 * glowAnim.value,
                          ),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Embossed seal ──
            Center(
              child: Padding(
                padding: EdgeInsets.only(top: height * 0.15),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 28,
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

class _EnvelopeBody extends StatelessWidget {
  const _EnvelopeBody({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _EnvelopeBodyPainter(),
    );
  }
}

class _EnvelopeBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Bottom triangular flap (V-shape from center to bottom)
    final bottomPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width / 2, size.height * 0.48)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(
      bottomPath,
      Paint()
        ..color =
            const Color(0xFF131A3A) // Slight shadow on bottom flap
        ..style = PaintingStyle.fill,
    );

    // Left and right diagonal lines (V from sides to center)
    final sidePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height * 0.52)
      ..lineTo(size.width, 0);

    canvas.drawPath(
      sidePath,
      Paint()
        ..color =
            const Color(0xFF0F1530) // Slightly darker than full white
        ..style = PaintingStyle.fill,
    );

    // Gold diagonal edges
    final edgePaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, 0),
      Offset(size.width / 2, size.height * 0.52),
      edgePaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width / 2, size.height * 0.52),
      edgePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnvelopeFlap extends StatelessWidget {
  const _EnvelopeFlap({required this.width});
  final double width;

  @override
  Widget build(BuildContext context) {
    final height = width * 0.4;
    return CustomPaint(
      size: Size(width, height),
      painter: _EnvelopeFlapPainter(),
    );
  }
}

class _EnvelopeFlapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    // Flap gradient
    final flapPaint = Paint();
    flapPaint.shader = LinearGradient(
      colors: [const Color(0xFF1C1250), const Color(0xFF111840)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, flapPaint);

    // Gold edge
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.4)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
