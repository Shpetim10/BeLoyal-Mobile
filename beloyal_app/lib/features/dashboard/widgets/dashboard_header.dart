import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/features/auth/domain/entities/auth_user.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/profile/presentation/controllers/profile_controller.dart';

/// Consistent top header used by every role dashboard.
///
/// Shows:
/// • Profile avatar (initials or person icon)
/// • "BesaHub" gradient logo text
/// • Role-switch chip (only when [canSwitchRoles] is true)
/// • Logout icon button (always)
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.canSwitchRoles,
    required this.activeRoleName,
    required this.onRoleSwitchTap,
    required this.onLogoutTap,
    this.subtitle,
    this.initials,
  });

  final bool canSwitchRoles;
  final String activeRoleName;
  final VoidCallback onRoleSwitchTap;
  final VoidCallback onLogoutTap;

  /// Optional subtitle shown beneath the header row (e.g. business name pill).
  final String? subtitle;

  /// Optional 1-2 letter initials for the avatar. Falls back to a person icon.
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── BesaHub logo ──
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppColors.accentGradient.createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: const Text(
                'BesaHub',
                style: TextStyle(
                  color: Colors.white, // masked by shader
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),

            const Spacer(),

            // ── Role-switch chip ──
            if (canSwitchRoles) ...[
              _RoleSwitchChip(roleName: activeRoleName, onTap: onRoleSwitchTap),
              const SizedBox(width: 12),
            ],

            // ── Profile Avatar Dropdown ──
            _ProfileDropdown(
              onLogoutTap: onLogoutTap,
              fallbackInitials: initials,
            ),
          ],
        ),

        // ── Optional subtitle pill (e.g. business name) ──
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              subtitle!,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────── Internal widgets ────────────────────────────────

class _ProfileDropdown extends ConsumerWidget {
  const _ProfileDropdown({required this.onLogoutTap, this.fallbackInitials});
  final VoidCallback onLogoutTap;
  final String? fallbackInitials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch profile to dynamically show avatar or initials
    final profileState = ref.watch(profileControllerProvider);
    final userProfile = profileState.value?.user;

    String? imageUrl = userProfile?.profileImageUrl;
    String initials = fallbackInitials ?? '';

    if (userProfile != null) {
      if (userProfile.firstName.isNotEmpty) {
        initials = userProfile.firstName[0].toUpperCase();
        if (userProfile.lastName.isNotEmpty) {
          initials += userProfile.lastName[0].toUpperCase();
        }
      } else if (userProfile.username.isNotEmpty) {
        initials = userProfile.username[0].toUpperCase();
      }
    }

    return PopupMenuButton<String>(
      tooltip: 'Profile Options',
      onSelected: (value) {
        if (value == 'profile') {
          // Business Admins go to the hub (has My Profile + Restaurant tabs)
          final session = ref.read(sessionControllerProvider);
          final role = session?.activeRole;
          if (role == UserRole.businessAdmin) {
            context.push('/admin/profile');
          } else {
            context.push('/profile');
          }
        } else if (value == 'logout') {
          onLogoutTap();
        }
      },
      offset: const Offset(0, 50),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: AppColors.glassBorder, width: 2),
          image: imageUrl != null && imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: (imageUrl == null || imageUrl.isEmpty)
            ? (initials.isNotEmpty
                  ? Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ))
            : null,
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 20, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'My Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout_rounded, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleSwitchChip extends StatelessWidget {
  const _RoleSwitchChip({required this.roleName, required this.onTap});
  final String roleName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              roleName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
