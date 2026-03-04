import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/section_card_widget.dart';
import '../../../profile/presentation/widgets/status_badge_widget.dart';

class LoyaltySettingsCard extends StatelessWidget {
  const LoyaltySettingsCard({
    super.key,
    required this.businessId,
    required this.configured,
    required this.enabled,
    required this.summaryText,
  });

  final int businessId;
  final bool configured;
  final bool enabled;
  final String summaryText;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Loyalty Settings',
      icon: Icons.card_giftcard_rounded,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Earning rule',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  summaryText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusBadgeWidget(
                      status: configured ? 'Configured' : 'Not configured',
                    ),
                    const SizedBox(width: 8),
                    if (configured)
                      StatusBadgeWidget(
                        status: enabled ? 'Enabled' : 'Disabled',
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: AppColors.glassBorder),
        ),
        InkWell(
          onTap: () {
            context.push('/business/$businessId/loyalty/earning-rule');
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Manage earning rule',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
