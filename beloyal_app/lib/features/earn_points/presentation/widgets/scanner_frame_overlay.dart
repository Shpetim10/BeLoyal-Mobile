import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';

/// Full-screen overlay for the QR scanner with a transparent focus window,
/// animated corner brackets, and helper text.
///
/// Draws a dimmed overlay with a rounded-rect cutout in the center.
class ScannerFrameOverlay extends StatefulWidget {
  const ScannerFrameOverlay({
    super.key,
    this.frameSize = 260,
    this.borderRadius = 24,
    this.helperText = 'Align the loyalty QR inside the frame',
    this.subText = 'The code will be detected automatically',
    this.isProcessing = false,
    this.errorMessage,
  });

  final double frameSize;
  final double borderRadius;
  final String helperText;
  final String subText;
  final bool isProcessing;
  final String? errorMessage;

  @override
  State<ScannerFrameOverlay> createState() => _ScannerFrameOverlayState();
}

class _ScannerFrameOverlayState extends State<ScannerFrameOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // ── Dimmed overlay with cutout ──
        CustomPaint(
          size: size,
          painter: _ScannerOverlayPainter(
            frameSize: widget.frameSize,
            borderRadius: widget.borderRadius,
          ),
        ),

        // ── Corner brackets (animated pulse) ──
        Transform.translate(
          offset: const Offset(0, -40),
          child: Center(
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(widget.frameSize + 16, widget.frameSize + 16),
                  painter: _CornerBracketsPainter(
                    opacity: widget.isProcessing ? 0.3 : _pulseAnim.value,
                    color: widget.errorMessage != null
                        ? AppColors.error
                        : AppColors.primary,
                  ),
                );
              },
            ),
          ),
        ),

        // ── Processing indicator ──
        if (widget.isProcessing)
          Transform.translate(
            offset: const Offset(0, -40),
            child: Center(
              child: SizedBox(
                width: widget.frameSize * 0.4,
                height: widget.frameSize * 0.4,
                child: const BesaLoader(),
              ),
            ),
          ),

        // ── Helper text below frame ──
        Positioned(
          left: 32,
          right: 32,
          bottom: size.height * 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error banner
              if (widget.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.errorMessage!,
                          style: const TextStyle(
                            color: AppColors.errorLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Primary helper
              Text(
                widget.errorMessage != null
                    ? 'Try again or search manually'
                    : widget.helperText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                ),
              ),
              const SizedBox(height: 6),

              // Secondary helper
              Text(
                widget.subText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  shadows: const [Shadow(color: Colors.black38, blurRadius: 6)],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Overlay painter (dim background with transparent cutout) ─────────────────

class _ScannerOverlayPainter extends CustomPainter {
  _ScannerOverlayPainter({required this.frameSize, required this.borderRadius});

  final double frameSize;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    // Full screen fill.
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Cutout rect centered.
    final cx = size.width / 2;
    final cy = size.height / 2 - 40; // Shift up slightly for visual balance.
    final cutout = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: frameSize,
        height: frameSize,
      ),
      Radius.circular(borderRadius),
    );

    // Draw full rect minus cutout.
    final path = Path()
      ..addRect(fullRect)
      ..addRRect(cutout);
    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter oldDelegate) =>
      oldDelegate.frameSize != frameSize ||
      oldDelegate.borderRadius != borderRadius;
}

// ── Corner brackets painter ─────────────────────────────────────────────────

class _CornerBracketsPainter extends CustomPainter {
  _CornerBracketsPainter({required this.opacity, required this.color});

  final double opacity;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 32.0;
    const radius = 16.0;

    // Each corner draws two lines forming an L shape.
    final corners = [
      // Top-left
      [
        Offset(0, cornerLen),
        Offset(0, radius),
        Offset(radius, 0),
        Offset(cornerLen, 0),
      ],
      // Top-right
      [
        Offset(size.width - cornerLen, 0),
        Offset(size.width - radius, 0),
        Offset(size.width, radius),
        Offset(size.width, cornerLen),
      ],
      // Bottom-right
      [
        Offset(size.width, size.height - cornerLen),
        Offset(size.width, size.height - radius),
        Offset(size.width - radius, size.height),
        Offset(size.width - cornerLen, size.height),
      ],
      // Bottom-left
      [
        Offset(cornerLen, size.height),
        Offset(radius, size.height),
        Offset(0, size.height - radius),
        Offset(0, size.height - cornerLen),
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..quadraticBezierTo(
          // corner point
          pts[0].dx == pts[1].dx ? pts[1].dx : pts[2].dx,
          pts[0].dy == pts[1].dy ? pts[1].dy : pts[2].dy,
          pts[2].dx,
          pts[2].dy,
        )
        ..lineTo(pts[3].dx, pts[3].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_CornerBracketsPainter oldDelegate) =>
      oldDelegate.opacity != opacity || oldDelegate.color != color;
}
