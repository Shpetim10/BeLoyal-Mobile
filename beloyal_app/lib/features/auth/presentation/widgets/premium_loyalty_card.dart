import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';

/// Premium digital loyalty card, credit-card-proportioned (1.586 ratio).
///
/// Displays [firstName], [lastName], [qrToken] zone, and [manualCode]
/// with luxury fintech aesthetics: dark holographic gradient, gold accents,
/// app logo, shimmer animation.
class PremiumLoyaltyCard extends StatefulWidget {
  const PremiumLoyaltyCard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.qrToken,
    required this.manualCode,
    this.shimmer = true,
  });

  final String firstName;
  final String lastName;
  final String qrToken;
  final String manualCode;

  /// Whether to run the continuous shimmer animation.
  final bool shimmer;

  @override
  State<PremiumLoyaltyCard> createState() => _PremiumLoyaltyCardState();
}

class _PremiumLoyaltyCardState extends State<PremiumLoyaltyCard>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _shimmerAnim = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
    if (widget.shimmer) {
      _shimmerCtrl.repeat();
    }
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Vertical VIP pass / mobile wallet aspect ratio: 1 / 1.586
        const ratio = 1.586;
        final width = constraints.maxWidth;
        final height = width * ratio;

        return SizedBox(
          width: width,
          height: height,
          child: AnimatedBuilder(
            animation: _shimmerAnim,
            builder: (context, _) => _buildCard(context, width, height),
          ),
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0D1B3E), // Deep navy
            Color(0xFF1A0B3B), // Royal purple-navy
            Color(0xFF0B2045), // Midnight blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Holographic background pattern ──
            _HolographicPattern(width: width, height: height),

            // ── Moving shimmer stripe ──
            if (widget.shimmer) _ShimmerStripe(progress: _shimmerAnim.value),

            // ── Gold edge border ──
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
              ),
            ),

            // ── Card content overlay ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.065,
                vertical: height * 0.08,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Top row: logo + label ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // App logo
                      Image.asset(
                        'assets/images/besahub_logo.png',
                        height: height * 0.15,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => Text(
                          'BeLoyal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: height * 0.09,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // Elite Rewards label (chip style)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: width * 0.03,
                          vertical: height * 0.02,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          'ELITE REWARDS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: height * 0.05,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 2),

                  // ── Center: Large QR area + code ──
                  Center(
                    child: Column(
                      children: [
                        // Large QR Code area
                        _QrPlaceholder(
                          size: height * 0.48,
                          token: widget.qrToken,
                        ),
                        SizedBox(height: height * 0.04),
                        // Manual code
                        _SpacedCode(
                          code: widget.manualCode,
                          fontSize: height * 0.08,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Bottom: Name and Brand Badging ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'EXCLUSIVE MEMBER',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: height * 0.045,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 2.0,
                              ),
                            ),
                            SizedBox(height: height * 0.015),
                            Text(
                              '${widget.firstName} ${widget.lastName}'
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: height * 0.1,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Optional: elite badge or visual anchor
                      Container(
                        width: height * 0.15,
                        height: height * 0.15,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          gradient: RadialGradient(
                            colors: [
                              AppColors.accent.withValues(alpha: 0.2),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.diamond_outlined,
                          color: AppColors.accent,
                          size: height * 0.08,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QR placeholder area ──────────────────────────────────────────────────────

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({required this.size, required this.token});
  final double size;
  final String token;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_rounded,
              size: size * 0.75,
              color: const Color(0xFF0D1B3E),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Letter-spaced member code ────────────────────────────────────────────────

class _SpacedCode extends StatelessWidget {
  const _SpacedCode({required this.code, required this.fontSize});
  final String code;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      code,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.9),
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 3.5,
        fontFamily: 'monospace',
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
    );
  }
}

// ─── Moving shimmer stripe ────────────────────────────────────────────────────

class _ShimmerStripe extends StatelessWidget {
  const _ShimmerStripe({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        // Progress goes from -1 to 2, map to diagonal position
        final offset = (progress * (w + h));

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateZ(math.pi / 4),
            origin: Offset(w / 2, h / 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Transform.translate(
                offset: Offset(offset - w, 0),
                child: Container(
                  width: w * 0.15,
                  height: h * 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.06),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Holographic background pattern ──────────────────────────────────────────

class _HolographicPattern extends StatelessWidget {
  const _HolographicPattern({required this.width, required this.height});
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _HolographicPainter(),
    );
  }
}

class _HolographicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large radial glow top-right
    paint.shader = RadialGradient(
      center: const Alignment(0.7, -0.6),
      radius: 0.9,
      colors: [
        const Color(0xFF7C3AED).withValues(alpha: 0.18),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Radial glow bottom-left
    paint.shader = RadialGradient(
      center: const Alignment(-0.7, 0.9),
      radius: 0.7,
      colors: [AppColors.accent.withValues(alpha: 0.12), Colors.transparent],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Subtle circuit lines
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 6; i++) {
      final y = size.height * 0.15 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width * 0.3, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(_HolographicPainter oldDelegate) => false;
}
