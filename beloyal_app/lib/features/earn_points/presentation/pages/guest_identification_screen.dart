import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/resolved_guest.dart';
import '../controllers/earn_points_controller.dart';
import '../widgets/scanner_frame_overlay.dart';
import '../widgets/resolved_guest_card.dart';
import '../widgets/manual_search_sheet.dart';

/// Step 1 of the Earn Points wizard.
///
/// Full-screen camera scanner with auto-QR detection, guest cards,
/// torch toggle, manual search fallback, and "Add another guest" flow.
class GuestIdentificationScreen extends ConsumerStatefulWidget {
  const GuestIdentificationScreen({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<GuestIdentificationScreen> createState() =>
      _GuestIdentificationScreenState();
}

class _GuestIdentificationScreenState
    extends ConsumerState<GuestIdentificationScreen> {
  MobileScannerController? _scannerController;
  bool _isTorchOn = false;
  bool _scannerStarted = false;

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    _scannerStarted = true;
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  // ── QR Detection Handler ──────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (!mounted) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    final ctrl = ref.read(earnPointsControllerProvider.notifier);
    final accepted = ctrl.onQrDetected(rawValue);

    if (accepted) {
      // Pause scanner during lookup.
      _scannerController?.stop();

      // Perform backend lookup.
      ctrl
          .lookupGuest(
            businessId: widget.businessId,
            qrToken: rawValue,
          )
          .then((_) {
        if (!mounted) return;
        final status = ref.read(earnPointsControllerProvider).scannerStatus;
        // If error, restart scanner so user can try again.
        if (status == ScannerStatus.error) {
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _scannerController?.start();
              ref.read(earnPointsControllerProvider.notifier).resumeScanning();
            }
          });
        }
      });
    }
  }

  // ── Torch Toggle ──────────────────────────────────────────────────────────

  void _toggleTorch() {
    _scannerController?.toggleTorch();
    setState(() => _isTorchOn = !_isTorchOn);
  }

  // ── Manual Search ─────────────────────────────────────────────────────────

  void _openManualSearch() {
    // Pause scanner while the sheet is open.
    _scannerController?.stop();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ManualSearchSheet(businessId: widget.businessId),
    ).then((_) {
      // Resume scanner if still on this screen and needing more guests.
      if (mounted) {
        final status = ref.read(earnPointsControllerProvider).scannerStatus;
        if (status == ScannerStatus.scanning) {
          _scannerController?.start();
        }
      }
    });
  }

  // ── Add Another Guest ─────────────────────────────────────────────────────

  void _addAnotherGuest() {
    final ctrl = ref.read(earnPointsControllerProvider.notifier);
    ctrl.resumeScanning();
    _scannerController?.start();
  }

  // ── Confirm Guests & Proceed ──────────────────────────────────────────────

  void _confirmGuests() {
    ref.read(earnPointsControllerProvider.notifier).confirmGuests();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(earnPointsControllerProvider);

    return Stack(
      children: [
        // ── Camera preview (full bleed) ──
        if (_scannerStarted && _scannerController != null)
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController!,
              onDetect: _onDetect,
              errorBuilder: (context, error, child) {
                return _CameraErrorView(
                  error: error,
                  onRetry: () {
                    _scannerController?.dispose();
                    _initScanner();
                    setState(() {});
                  },
                );
              },
            ),
          ),

        // ── Scanner overlay ──
        Positioned.fill(
          child: ScannerFrameOverlay(
            isProcessing: draft.scannerStatus == ScannerStatus.lookingUp,
            errorMessage: draft.scannerErrorMessage,
          ),
        ),

        // ── Top bar (back, title, torch) ──
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
                  // Back button
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
                      'Earn Points',
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
                  // Torch toggle
                  IconButton(
                    onPressed: _toggleTorch,
                    icon: Icon(
                      _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                    ),
                    color: _isTorchOn ? AppColors.accent : Colors.white,
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

        // ── Bottom panel (guests + actions) ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _BottomPanel(
            guests: draft.guests,
            scannerStatus: draft.scannerStatus,
            canAddGuest: draft.canAddGuest,
            onRemoveGuest: (id) {
              ref
                  .read(earnPointsControllerProvider.notifier)
                  .removeGuest(id);
              // Resume scanner if list becomes empty.
              if (ref.read(earnPointsControllerProvider).guests.isEmpty) {
                _scannerController?.start();
              }
            },
            onAddAnother: _addAnotherGuest,
            onSearchManually: _openManualSearch,
            onContinue: _confirmGuests,
          ),
        ),
      ],
    );
  }
}

// ── Bottom panel widget ─────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.guests,
    required this.scannerStatus,
    required this.canAddGuest,
    required this.onRemoveGuest,
    required this.onAddAnother,
    required this.onSearchManually,
    required this.onContinue,
  });

  final List<ResolvedGuest> guests;
  final ScannerStatus scannerStatus;
  final bool canAddGuest;
  final ValueChanged<int> onRemoveGuest;
  final VoidCallback onAddAnother;
  final VoidCallback onSearchManually;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.6),
            Colors.black.withValues(alpha: 0.85),
          ],
          stops: const [0.0, 0.3, 1.0],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, 24, 20, 16 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Guest cards ──
          if (guests.isNotEmpty) ...[
            ...guests.map(
              (guest) => ResolvedGuestCard(
                guest: guest,
                onRemove: () => onRemoveGuest(guest.customerId),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // ── Action row: Add another + Search manually ──
          if (scannerStatus == ScannerStatus.resolved && guests.isNotEmpty)
            Row(
              children: [
                if (canAddGuest)
                  Expanded(
                    child: _ActionChip(
                      icon: Icons.person_add_alt_1_rounded,
                      label: 'Add another guest',
                      onTap: onAddAnother,
                    ),
                  ),
                if (canAddGuest) const SizedBox(width: 10),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.search_rounded,
                    label: 'Search manually',
                    onTap: onSearchManually,
                    outlined: true,
                  ),
                ),
              ],
            )
          else
            // When scanning (no guest yet), show search fallback.
            _ActionChip(
              icon: Icons.search_rounded,
              label: 'Search manually',
              onTap: onSearchManually,
              outlined: true,
            ),

          const SizedBox(height: 14),

          // ── Continue button ──
          AnimatedOpacity(
            opacity: guests.isNotEmpty ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: AnimatedSlide(
              offset: guests.isNotEmpty ? Offset.zero : const Offset(0, 0.3),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: guests.isNotEmpty ? onContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(
                    guests.length == 1
                        ? 'Continue with ${guests.first.fullName}'
                        : 'Continue with ${guests.length} guests',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action chip button ──────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: outlined
              ? Colors.transparent
              : AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: outlined
                ? Colors.white.withValues(alpha: 0.25)
                : AppColors.primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Camera error view ───────────────────────────────────────────────────────

class _CameraErrorView extends StatelessWidget {
  const _CameraErrorView({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Camera permission is required to scan QR codes.\n'
            'Please grant access in Settings.';
        icon = Icons.no_photography_rounded;
        break;
      default:
        message = 'Camera error: ${error.errorDetails?.message ?? 'Unknown'}.\n'
            'Tap to retry.';
        icon = Icons.videocam_off_rounded;
    }

    return Container(
      color: AppColors.bgDark,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 15,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
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
