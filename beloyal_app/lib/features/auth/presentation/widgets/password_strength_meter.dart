import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PasswordStrengthMeter extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrengthMeter({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        final password = value.text;
        bool len = password.length >= 8;
        bool ul = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(password);
        bool ns = RegExp(r'(?=.*\d)(?=.*[@$!%*?&])').hasMatch(password);

        double strength = 0;
        if (len) strength += 0.33;
        if (ul) strength += 0.33;
        if (ns) strength += 0.34;

        Color getStrColor() {
          if (strength < 0.4) return AppColors.error;
          if (strength < 0.7) return AppColors.warning;
          return AppColors.secondary;
        }

        Widget rule(String text, bool met) {
          return Row(
            children: [
              Icon(
                met
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 14,
                color: met
                    ? AppColors.secondary
                    : AppColors.textMuted.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: met ? AppColors.textOnDark : AppColors.textMuted,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: strength),
                duration: const Duration(milliseconds: 300),
                builder: (context, tweenValue, _) => LinearProgressIndicator(
                  value: tweenValue,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
                  color: getStrColor(),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            rule('At least 8 characters', len),
            const SizedBox(height: 4),
            rule('Uppercase & lowercase letters', ul),
            const SizedBox(height: 4),
            rule('Number & special character', ns),
          ],
        );
      },
    );
  }
}
