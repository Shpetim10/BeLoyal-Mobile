import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';

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
            // ── Profile avatar ──
            _Avatar(initials: initials),
            const SizedBox(width: 12),

            // ── BesaHub logo ──
            Expanded(
              child: ShaderMask(
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
            ),

            // ── Role-switch chip ──
            if (canSwitchRoles) ...[
              _RoleSwitchChip(roleName: activeRoleName, onTap: onRoleSwitchTap),
              const SizedBox(width: 6),
            ],

            // ── Logout button ──
            Tooltip(
              message: 'Log Out',
              child: InkWell(
                onTap: onLogoutTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.logout_rounded,
                    color: AppColors.textMuted,
                    size: 22,
                  ),
                ),
              ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({this.initials});
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: AppColors.glassBorder, width: 2),
      ),
      child: initials != null && initials!.isNotEmpty
          ? Center(
              child: Text(
                initials!.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            )
          : const Icon(Icons.person_rounded, color: Colors.white, size: 22),
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
