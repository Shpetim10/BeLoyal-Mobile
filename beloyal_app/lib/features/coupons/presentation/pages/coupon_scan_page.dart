import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/coupon_repository.dart';
import '../../../earn_points/presentation/widgets/scanner_frame_overlay.dart';

// ── State ─────────────────────────────────────────────────────────────────────

abstract class CouponScanState {
  const CouponScanState();
}

class CouponScanIdle extends CouponScanState {
  const CouponScanIdle();
}

class CouponScanProcessing extends CouponScanState {
  const CouponScanProcessing();
}

class CouponScanSuccess extends CouponScanState {
  const CouponScanSuccess(this.result);
  final CouponScanResult result;
}

class CouponScanError extends CouponScanState {
  const CouponScanError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class CouponScanNotifier extends Notifier<CouponScanState> {
  final _scannedTokens = <String>{};

  @override
  CouponScanState build() => const CouponScanIdle();

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  bool canScan(String token) {
    if (state is CouponScanProcessing) return false;
    return _scannedTokens.add(token);
  }

  Future<void> scan({
    required int businessId,
    required String qrCode,
  }) async {
    state = const CouponScanProcessing();
    try {
      final result = await _repo.scanCoupon(
        businessId: businessId,
        qrCode: qrCode,
      );
      state = CouponScanSuccess(result);
    } catch (e) {
      state = CouponScanError(_extractMessage(e));
    }
  }

  void reset() {
    _scannedTokens.clear();
    state = const CouponScanIdle();
  }

  void resumeAfterError() {
    state = const CouponScanIdle();
  }

  String _extractMessage(Object e) {
    final str = e.toString();
    if (str.contains('already been used') || str.contains('409')) {
      return 'This coupon has already been used.';
    }
    if (str.contains('not found') || str.contains('404') || str.contains('unrecognized')) {
      return 'QR code not recognised. Try scanning again.';
    }
    if (str.contains('FREE_PRODUCT') || str.contains('422')) {
      return 'This coupon type cannot be scanned here.';
    }
    return 'Something went wrong. Please try again.';
  }
}

final couponScanProvider =
    NotifierProvider<CouponScanNotifier, CouponScanState>(
  CouponScanNotifier.new,
);

// ── Page ──────────────────────────────────────────────────────────────────────

class CouponScanPage extends ConsumerStatefulWidget {
  const CouponScanPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponScanPage> createState() => _CouponScanPageState();
}

class _CouponScanPageState extends ConsumerState<CouponScanPage> {
  MobileScannerController? _scanner;
  bool _torchOn = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(couponScanProvider.notifier).reset();
    });
    _scanner = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _started = true;
  }

  @override
  void dispose() {
    _scanner?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;

    final notifier = ref.read(couponScanProvider.notifier);
    if (!notifier.canScan(raw)) return;

    _scanner?.stop();
    notifier.scan(businessId: widget.businessId, qrCode: raw);
  }

  void _toggleTorch() {
    _scanner?.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  void _retry() {
    ref.read(couponScanProvider.notifier).resumeAfterError();
    _scanner?.start();
  }

  void _scanAnother() {
    ref.read(couponScanProvider.notifier).reset();
    _scanner?.start();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(couponScanProvider);

    ref.listen<CouponScanState>(couponScanProvider, (_, next) {
      if (next is CouponScanError) {
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && ref.read(couponScanProvider) is CouponScanError) {
            _retry();
          }
        });
      }
    });

    final isProcessing = state is CouponScanProcessing;
    final errorMsg = state is CouponScanError ? (state).message : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera
          if (_started && _scanner != null)
            Positioned.fill(
              child: MobileScanner(
                controller: _scanner!,
                onDetect: _onDetect,
                errorBuilder: (_, error) => _CameraError(
                  error: error,
                  onRetry: () {
                    _scanner?.dispose();
                    setState(() {
                      _scanner = MobileScannerController(
                        detectionSpeed: DetectionSpeed.normal,
                        facing: CameraFacing.back,
                      );
                    });
                  },
                ),
              ),
            ),

          // Scan overlay
          Positioned.fill(
            child: ScannerFrameOverlay(
              isProcessing: isProcessing,
              errorMessage: errorMsg,
            ),
          ),

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
                      onPressed: () => Navigator.of(context).pop(),
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
                        'Scan Coupon QR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          shadows: [Shadow(color: Colors.black38, blurRadius: 8)],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _toggleTorch,
                      icon: Icon(
                        _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
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

          // Bottom panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(
              state: state,
              onScanAnother: _scanAnother,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom panel ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.state,
    required this.onScanAnother,
    required this.onClose,
  });

  final CouponScanState state;
  final VoidCallback onScanAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    Widget child;
    if (state is CouponScanSuccess) {
      child = _SuccessPanel(
        key: const ValueKey('success'),
        result: (state as CouponScanSuccess).result,
        onScanAnother: onScanAnother,
        onClose: onClose,
      );
    } else if (state is CouponScanError) {
      child = _ErrorHint(
        key: const ValueKey('error'),
        message: (state as CouponScanError).message,
      );
    } else if (state is CouponScanProcessing) {
      child = _ProcessingHint(key: const ValueKey('processing'));
    } else {
      child = _IdleHint(key: const ValueKey('idle'));
    }

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
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }
}

class _IdleHint extends StatelessWidget {
  const _IdleHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Point the camera at the customer\'s coupon QR code to mark it as used.',
              style: AppTypography.dmSans(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingHint extends StatelessWidget {
  const _ProcessingHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: BesaLoader(size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            'Validating coupon…',
            style: AppTypography.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessPanel extends StatelessWidget {
  const _SuccessPanel({
    super.key,
    required this.result,
    required this.onScanAnother,
    required this.onClose,
  });

  final CouponScanResult result;
  final VoidCallback onScanAnother;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Coupon Redeemed!',
                      style: AppTypography.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                result.couponTitle,
                style: AppTypography.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Marked as ${result.status}',
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onScanAnother,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'Scan Another',
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorHint extends StatelessWidget {
  const _ErrorHint({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.dmSans(
                fontSize: 13,
                color: AppColors.error,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Camera error ──────────────────────────────────────────────────────────────

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
          const Icon(Icons.videocam_off_rounded, size: 56, color: AppColors.textMuted),
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
