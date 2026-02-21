import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/auth_user.dart';
import '../widgets/role_chip.dart';

/// Premium modal bottom sheet for role selection when user has multiple roles or business profiles.
class RoleSelectSheet extends StatefulWidget {
  const RoleSelectSheet({
    super.key,
    required this.roles,
    required this.businessProfiles,
  });

  final List<UserRole> roles;
  final List<BusinessProfileInfo> businessProfiles;

  @override
  State<RoleSelectSheet> createState() => _RoleSelectSheetState();
}

class _RoleSelectSheetState extends State<RoleSelectSheet> {
  UserRole? _selectedRole;
  int? _selectedBusinessId;

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
            'You have multiple options. Select which one to use for this session.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),

          // Standard Roles
          ...widget.roles.asMap().entries.map((entry) {
            final idx = entry.key;
            final role = entry.value;
            // If it's businessAdmin or STAFF, we handle it via the business list instead if applicable
            // But usually, roles list might contain CUSTOMER or PLATFORM_ADMIN which are distinct.
            return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoleChip(
                    role: role,
                    selected:
                        _selectedRole == role && _selectedBusinessId == null,
                    onTap: () => setState(() {
                      _selectedRole = role;
                      _selectedBusinessId = null;
                    }),
                  ),
                )
                .animate()
                .fadeIn(delay: (100 * idx).ms, duration: 300.ms)
                .slideX(begin: 0.1, end: 0, duration: 300.ms);
          }),

          // Business Profiles
          ...widget.businessProfiles.asMap().entries.map((entry) {
            final idx = entry.key;
            final profile = entry.value;
            return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BusinessChip(
                    businessId: profile.businessId,
                    businessName: profile.businessName,
                    role: profile.role,
                    active: profile.active,
                    selected: _selectedBusinessId == profile.businessId,
                    onTap: () => setState(() {
                      _selectedRole = profile.role;
                      _selectedBusinessId = profile.businessId;
                    }),
                  ),
                )
                .animate()
                .fadeIn(
                  delay: (100 * (widget.roles.length + idx)).ms,
                  duration: 300.ms,
                )
                .slideX(begin: 0.1, end: 0, duration: 300.ms);
          }),

          const SizedBox(height: 12),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedRole == null
                  ? null
                  : () {
                      Navigator.of(context).pop({
                        'role': _selectedRole,
                        'businessId': _selectedBusinessId,
                        'businessName': widget.businessProfiles
                            .where((p) => p.businessId == _selectedBusinessId)
                            .firstOrNull
                            ?.businessName,
                      });
                    },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessChip extends StatelessWidget {
  const _BusinessChip({
    required this.businessId,
    required this.businessName,
    required this.role,
    required this.active,
    required this.selected,
    required this.onTap,
  });

  final int businessId;
  final String businessName;
  final UserRole role;
  final bool active;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textMuted.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                role == UserRole.staff
                    ? Icons.badge_outlined
                    : Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        role.displayName,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (!active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Under Review',
                            style: TextStyle(
                              color: AppColors.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (active && selected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            if (!active)
              const Icon(
                Icons.hourglass_empty_rounded,
                color: AppColors.warning,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
