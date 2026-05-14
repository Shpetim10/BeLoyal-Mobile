import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/scanner_frame_overlay.dart';

/// Lightweight full-screen QR scanner used in the earn-points flow
/// to capture a customer's discount coupon QR code.
///
/// Pops with `String qrCode` on a successful scan, or null if cancelled.
class DiscountCouponScanPage extends StatefulWidget {
  const DiscountCouponScanPage({super.key});

  @override
  State<DiscountCouponScanPage> createState() => _DiscountCouponScanPageState();
}

class _DiscountCouponScanPageState extends State<DiscountCouponScanPage> {
  late final MobileScannerController _scanner;
  bool _torchOn = false;
  bool _scanned = false;

  @override
  void initState() {
    super.initState();
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned || !mounted) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    _scanned = true;
    _scanner.stop();
    Navigator.of(context).pop(raw);
  }

  void _toggleTorch() {
    _scanner.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scanner,
              onDetect: _onDetect,
              errorBuilder: (_, error) => _CameraError(
                error: error,
                onRetry: () {
                  _scanner.dispose();
                  setState(() {
                    _scanned = false;
                  });
                },
              ),
            ),
          ),

          Positioned.fill(child: ScannerFrameOverlay(isProcessing: false)),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: Colors.white,
                      iconSize: 26,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                        shape: const CircleBorder(),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Scan Discount Coupon',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [
                            Shadow(color: Colors.black38, blurRadius: 8),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleTorch,
                      icon: Icon(
                        _torchOn
                            ? Icons.flash_on_rounded
                            : Icons.flash_off_rounded,
                      ),
                      color: _torchOn ? AppColors.accent : Colors.white,
                      iconSize: 24,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black26,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom hint
          Positioned(bottom: 0, left: 0, right: 0, child: _BottomHint()),
        ],
      ),
    );
  }
}

class _BottomHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.9),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 28, 20, 16 + bottomPad),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Point the camera at the customer\'s discount coupon QR code.',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.9),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error, required this.onRetry});
  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error.errorCode == MobileScannerErrorCode.permissionDenied
        ? 'Camera permission required.\nPlease grant access in Settings.'
        : 'Camera error. Tap to retry.';
    return Container(
      color: AppColors.bgDark,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.videocam_off_rounded,
            size: 56,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.textOnDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
