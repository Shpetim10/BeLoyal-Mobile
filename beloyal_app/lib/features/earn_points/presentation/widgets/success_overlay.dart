import 'dart:async';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';

/// Success overlay shown after transaction submission.
///
/// Displays animated checkmark, confetti, points awarded message,
/// and auto-dismisses after 2.5 seconds.
class SuccessOverlay extends StatefulWidget {
  const SuccessOverlay({
    super.key,
    required this.totalPointsAwarded,
    required this.guestNames,
    required this.onDismiss,
  });

  final int totalPointsAwarded;
  final List<String> guestNames;
  final VoidCallback onDismiss;

  @override
  State<SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<SuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnim;
  late final ConfettiController _confettiController;
  Timer? _autoDismiss;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // Start animations.
    _scaleController.forward();
    _confettiController.play();

    // Auto-dismiss after 2.5s.
    _autoDismiss = Timer(const Duration(milliseconds: 2500), widget.onDismiss);
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final guestText = widget.guestNames.length == 1
        ? 'to ${widget.guestNames.first}'
        : 'to ${widget.guestNames.length} guests';

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: AppColors.bgDark.withValues(alpha: 0.92),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ── Confetti ──
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 20,
              emissionFrequency: 0.05,
              gravity: 0.2,
              colors: const [
                AppColors.accent,
                AppColors.primary,
                AppColors.secondary,
                AppColors.primaryLight,
                AppColors.accentLight,
              ],
            ),

            // ── Content ──
            ScaleTransition(
              scale: _scaleAnim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark circle
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondaryLight,
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppColors.secondary.withValues(alpha: 0.4),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Points text
                  Text(
                    '+${widget.totalPointsAwarded} Points Awarded!',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Guest text
                  Text(
                    guestText,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Tap to dismiss hint
                  Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
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
