import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/dashboard/widgets/stat_card.dart';
import '../controllers/staff_controller.dart';

/// Horizontal row of frosted summary cards using the existing [StatCard].
class StaffSummaryRow extends ConsumerWidget {
  const StaffSummaryRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only rebuild counts; let individual cards handle the display
    final summary = ref.watch(staffSummaryProvider);
    final asyncStaff = ref.watch(staffControllerProvider);

    // Show skeletons while initially loading
    if (asyncStaff.isLoading && !asyncStaff.hasValue) {
      return const _SummarySkeletons();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child:
          Row(
                children: [
                  _buildCard(
                    'Total Staff',
                    summary.total.toString(),
                    Icons.people_alt_rounded,
                    AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildCard(
                    'Active',
                    summary.active.toString(),
                    Icons.person_pin_circle_rounded,
                    AppColors.secondary,
                  ),
                  const SizedBox(width: 12),
                  _buildCard(
                    'Inactive',
                    summary.inactive.toString(),
                    Icons.person_off_rounded,
                    AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  _buildCard(
                    'Pending',
                    summary.pending.toString(),
                    Icons.mark_email_unread_rounded,
                    AppColors.accent,
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .slideX(begin: 0.1, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildCard(String label, String value, IconData icon, Color color) {
    return SizedBox(
      width: 130, // Fixed width for horizontal scrolling
      height: 120, // Match the proportion of the grid stat cards
      child: StatCard(label: label, value: value, icon: icon, iconColor: color),
    );
  }
}

class _SummarySkeletons extends StatelessWidget {
  const _SummarySkeletons();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(
          4,
          (index) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child:
                Container(
                      width: 130,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                    )
                    .animate(onPlay: (controller) => controller.repeat())
                    .shimmer(duration: 1500.ms, color: Colors.white12),
          ),
        ),
      ),
    );
  }
}
