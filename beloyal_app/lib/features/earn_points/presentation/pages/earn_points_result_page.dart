import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../controllers/earn_points_controller.dart';
import '../widgets/points_explosion_animation.dart';

class EarnPointsResultPage extends ConsumerStatefulWidget {
  const EarnPointsResultPage({super.key});

  @override
  ConsumerState<EarnPointsResultPage> createState() => _EarnPointsResultPageState();
}

class _EarnPointsResultPageState extends ConsumerState<EarnPointsResultPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeInController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeInController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeInController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _fadeInController.forward();
    
    // Provide haptic feedback on success
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.mediumImpact());
  }

  @override
  void dispose() {
    _fadeInController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(earnPointsControllerProvider);
    final result = draft.finalResult;

    if (result == null) return const Scaffold(backgroundColor: AppColors.bgDark);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          // ── Explosion Background ──
          Positioned.fill(
            child: PointsExplosionAnimation(
              points: result.totalPoints,
            ),
          ),

          // ── Main Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // ── Success Icon / Header ──
                  const Center(
                    child: Hero(
                      tag: 'success_icon',
                      child: Icon(
                        Icons.stars_rounded,
                        color: AppColors.accent,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'TRANSACTION SUCCESSFUL',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // ── Points Count ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '+${result.totalPoints}',
                        style: const TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 64,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12, left: 8),
                        child: Text(
                          'PTS',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),

                  // ── Details Card ──
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _ResultSection(
                          title: 'BILL DETAILS',
                          children: [
                            _InfoRow(
                              label: 'Reference',
                              value: result.transactionReference ?? 'N/A',
                              isSecondary: true,
                            ),
                            _InfoRow(
                              label: 'Total Bill',
                              value: '${result.billAmount?.toStringAsFixed(0) ?? "--"} ALL',
                            ),
                            if (result.note != null && result.note!.isNotEmpty)
                              _InfoRow(label: 'Note', value: result.note!),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _ResultSection(
                          title: 'GUEST EARNINGS',
                          children: [
                            for (final gResult in result.guestPointsResults)
                              _GuestResultTile(
                                gResult: gResult,
                                guest: draft.guests.firstWhere(
                                  (g) => g.customerId == gResult.customerId,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 100), // Space for button
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom Action ──
          Positioned(
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 20,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    ref.read(earnPointsControllerProvider.notifier).reset();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.bgDark,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
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

class _ResultSection extends StatelessWidget {
  const _ResultSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.isSecondary = false,
  });
  final String label;
  final String value;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isSecondary ? AppColors.textMuted : AppColors.textOnDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestResultTile extends StatelessWidget {
  const _GuestResultTile({required this.gResult, required this.guest});
  final dynamic gResult; // GuestPointsResult
  final dynamic guest; // ResolvedGuest

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            child: Text(
              guest.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  guest.fullName,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'New Balance: ${gResult.currentBalance} pts',
                  style: TextStyle(
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '+${gResult.earnedPoints}',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
