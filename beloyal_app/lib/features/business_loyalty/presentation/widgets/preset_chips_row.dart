import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class PresetChipsRow extends StatelessWidget {
  const PresetChipsRow({super.key, required this.onSelect});

  final void Function(int points, int amount) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Quick presets',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _PresetChip(label: '1 per 100', onTap: () => onSelect(1, 100)),
              const SizedBox(width: 8),
              _PresetChip(label: '1 per 200', onTap: () => onSelect(1, 200)),
              const SizedBox(width: 8),
              _PresetChip(label: '2 per 100', onTap: () => onSelect(2, 100)),
              const SizedBox(width: 8),
              _PresetChip(label: '5 per 500', onTap: () => onSelect(5, 500)),
            ],
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      side: const BorderSide(color: AppColors.primary, width: 0.5),
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
