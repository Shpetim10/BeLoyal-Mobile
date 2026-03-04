import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/section_card_widget.dart';

class EarningRulePreviewCard extends StatelessWidget {
  const EarningRulePreviewCard({
    super.key,
    required this.pointsPer,
    required this.amountPer,
  });

  final int pointsPer;
  final int amountPer;

  @override
  Widget build(BuildContext context) {
    if (amountPer <= 0 || pointsPer < 0) {
      return const SizedBox.shrink();
    }

    int calc(int bill) {
      return (bill ~/ amountPer) * pointsPer;
    }

    return SectionCardWidget(
      title: 'Example earnings',
      icon: Icons.visibility_rounded,
      children: [
        _PreviewRow(bill: 100, points: calc(100)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.glassBorder),
        ),
        _PreviewRow(bill: 250, points: calc(250)),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.glassBorder),
        ),
        _PreviewRow(bill: 1000, points: calc(1000)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "We always round down. Partial amounts don't earn points.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.bill, required this.points});

  final int bill;
  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bill $bill ALL',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '$points points',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
