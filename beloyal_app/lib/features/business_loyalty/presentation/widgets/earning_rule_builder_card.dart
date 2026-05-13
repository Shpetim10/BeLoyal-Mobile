import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/section_card_widget.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';

class EarningRuleBuilderCard extends StatelessWidget {
  const EarningRuleBuilderCard({
    super.key,
    required this.pointsController,
    required this.amountController,
    this.currencyCode = 'ALL',
  });

  final TextEditingController pointsController;
  final TextEditingController amountController;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Rule Builder',
      icon: Icons.tune_rounded,
      children: [
        // Points Per
        PremiumTextField(
          controller: pointsController,
          label: 'Guests earn',
          hint: 'e.g., 1',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefixIcon: Icons.star_rounded,
          suffixIcon: const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Points cannot be empty';
            final points = int.tryParse(v);
            if (points == null || points < 0) return 'Must be 0 or greater';
            return null;
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Set to 0 to temporarily disable earning.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        // Amount Per
        PremiumTextField(
          controller: amountController,
          label: 'For every',
          hint: 'e.g., 100',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          prefixIcon: Icons.payments_rounded,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currencyCode,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Amount cannot be empty';
            final amount = double.tryParse(v);
            if (amount == null || amount <= 0) return 'Must be greater than 0';
            return null;
          },
        ),
      ],
    );
  }
}
