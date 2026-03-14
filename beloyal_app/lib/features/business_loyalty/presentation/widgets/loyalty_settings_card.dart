import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/section_card_widget.dart';
import '../../../profile/presentation/widgets/status_badge_widget.dart';

/// Card displayed on the Business Profile tab summarising loyalty configuration.
/// Shows two navigation rows: one for the earning rule, one for loyalty settings.
class LoyaltySettingsCard extends StatelessWidget {
  const LoyaltySettingsCard({
    super.key,
    required this.businessId,
    required this.configured,
    required this.enabled,
    required this.summaryText,
    this.loyaltyConfigured = false,
    this.loyaltyEnabled = false,
  });

  final int businessId;
  final bool configured;
  final bool enabled;
  final String summaryText;
  final bool loyaltyConfigured;
  final bool loyaltyEnabled;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Loyalty Programme',
      icon: Icons.card_giftcard_rounded,
      children: [
        _SummaryRow(
          label: 'Earning rule',
          summaryText: summaryText,
          configured: configured,
          enabled: enabled,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.glassBorder),
        ),
        _SummaryRow(
          label: 'Loyalty settings',
          summaryText: loyaltyConfigured
              ? 'Redemption policies active'
              : 'Not set up yet',
          configured: loyaltyConfigured,
          enabled: loyaltyEnabled,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(color: AppColors.glassBorder),
        ),
        _NavRow(
          label: 'Manage earning rule',
          onTap: () =>
              context.push('/business/$businessId/loyalty/earning-rule'),
        ),
        const SizedBox(height: 4),
        _NavRow(
          label: 'Manage loyalty settings',
          onTap: () => context.push('/business/$businessId/loyalty/settings'),
          highlight: !loyaltyConfigured,
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.summaryText,
    required this.configured,
    required this.enabled,
  });

  final String label;
  final String summaryText;
  final bool configured;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
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
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            StatusBadgeWidget(
              status: configured ? 'Configured' : 'Not configured',
            ),
            if (configured) ...[
              const SizedBox(height: 4),
              StatusBadgeWidget(status: enabled ? 'Enabled' : 'Disabled'),
            ],
          ],
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.accent : AppColors.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (highlight) ...[
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(fontWeight: FontWeight.w600, color: color),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
