import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_user.dart';
import '../widgets/role_chip.dart';

/// Premium modal bottom sheet for role selection when user has multiple roles.
class RoleSelectSheet extends StatefulWidget {
  const RoleSelectSheet({super.key, required this.roles});

  final List<UserRole> roles;

  @override
  State<RoleSelectSheet> createState() => _RoleSelectSheetState();
}

class _RoleSelectSheetState extends State<RoleSelectSheet> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Row(
            children: [
              const Icon(
                Icons.swap_horiz_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Choose your role',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have multiple roles. Select which one to use for this session.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Role chips
          ...widget.roles.asMap().entries.map((entry) {
            final idx = entry.key;
            final role = entry.value;
            return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoleChip(
                    role: role,
                    selected: _selected == role,
                    onTap: () => setState(() => _selected = role),
                  ),
                )
                .animate()
                .fadeIn(delay: (100 * idx).ms, duration: 300.ms)
                .slideX(begin: 0.1, end: 0, duration: 300.ms);
          }),

          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}
