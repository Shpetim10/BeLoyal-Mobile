import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/widgets/besa_loader.dart';

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
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final Animation<double> _shimmerAnim;

  late final ImageProvider _cardImageProvider;
  bool _isImageLoaded = false;
  bool _imageLoadingRequested = false;

  @override
  void initState() {
    super.initState();
    _cardImageProvider =
        const AssetImage('assets/images/loyalty_card_template.png');

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _shimmerAnim = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _shimmerCtrl, curve: Curves.linear));
    if (widget.shimmer) _shimmerCtrl.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_imageLoadingRequested) {
      _imageLoadingRequested = true;
      precacheImage(_cardImageProvider, context).then((_) {
        if (mounted) {
          setState(() {
            _isImageLoaded = true;
          });
        }
      });
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
        // Vertical VIP pass / mobile wallet aspect ratio — unchanged from before
        const ratio = 1.5;
        final width = constraints.maxWidth;
        final height = width * ratio;

        return SizedBox(
          width: width,
          height: height,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            switchInCurve: Curves.easeIn,
            switchOutCurve: Curves.easeOut,
            child: !_isImageLoaded
                ? _buildLoaderCard(width, height)
                : AnimatedBuilder(
                    key: const ValueKey('loadedCard'),
                    animation: _shimmerAnim,
                    builder: (_, __) => _buildCard(width, height),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLoaderCard(double width, double height) {
    return Container(
      key: const ValueKey('loaderCard'),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF071120), // Deep blue luxury background
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(
        child: BesaLoader(size: 36.0),
      ),
    );
  }

  Widget _buildCard(double width, double height) {
    // Vlerat e reja të kalibruara bazuar në screenshot-in tënd
    const double nameFraction   = 0.205;
    const double qrTopFraction  = 0.305;
    const double qrSizeFraction = 0.280;
    const double codeFraction   = 0.655;
    const double hPadFraction =
        0.10; // left+right padding fraction of card width

    final qrSize = height * qrSizeFraction;
    final hPad = width * hPadFraction;

    // Gold text style — shared by name & manual code
    final goldStyle = GoogleFonts.cinzel(
      color: const Color(0xFFFFD700),
      fontWeight: FontWeight.w700,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
        Shadow(color: Color(0x88D4AF37), blurRadius: 12),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.25),
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
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(
                child: Image(
                  image: _cardImageProvider,
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0D1B3E), Color(0xFF1A0B3B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: height * nameFraction,
                left: hPad,
                right: hPad,
                child: Center(
                  child: Text(
                    '${widget.firstName} ${widget.lastName}'
                        .trim()
                        .toUpperCase(),
                    style: goldStyle.copyWith(
                      fontSize: _responsiveFontSize(width, min: 14, max: 22),
                      letterSpacing: _clamp(width * 0.025, 1.5, 4.0),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: height * qrTopFraction,
                left: (width - qrSize) / 2,
                width: qrSize,
                height: qrSize,
                child: QrImageView(
                  data: widget.qrToken.isNotEmpty
                      ? widget.qrToken
                      : 'BESAHUB-CARD',
                  version: QrVersions.auto,
                  size: qrSize,
                  // Transparent bg — glowing nebula shines through the QR gaps
                  backgroundColor: Colors.transparent,
                  eyeStyle: QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: const Color(0xFF071120).withValues(alpha: 0.9),
                  ),
                  dataModuleStyle: QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: const Color(0xFF071120).withValues(alpha: 0.9),
                  ),
                  padding: EdgeInsets.all(qrSize * 0.035),
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                  semanticsLabel: 'Loyalty card QR code',
                ),
              ),
              Positioned(
                top: height * codeFraction,
                left: hPad,
                right: hPad,
                child: Center(
                  child: Text(
                    widget.manualCode.toUpperCase(),
                    style: goldStyle.copyWith(
                      fontSize: _responsiveFontSize(width, min: 15, max: 24),
                      letterSpacing: _clamp(width * 0.03, 2.0, 5.0),
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (widget.shimmer) _ShimmerStripe(progress: _shimmerAnim.value),
            ],
          ),
        ),
      ),
    );
  }

  /// Clamps a value between [min] and [max].
  double _clamp(double value, double min, double max) => value.clamp(min, max);

  /// Returns a font size that scales with card width, clamped to [min]..[max].
  double _responsiveFontSize(
    double width, {
    required double min,
    required double max,
  }) => _clamp(width * 0.058, min, max);
}

class _ShimmerStripe extends StatelessWidget {
  const _ShimmerStripe({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final offset = progress * (w + h);

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
                  width: w * 0.12,
                  height: h * 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.08),
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
