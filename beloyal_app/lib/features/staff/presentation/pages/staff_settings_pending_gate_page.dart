import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/models/session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/pages/role_select_sheet.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';

/// Gate page shown to staff members when the business admin has not yet
/// completed the loyalty and earning settings configuration.
/// Staff cannot use any features until the admin finishes setup.
class StaffSettingsPendingGatePage extends ConsumerWidget {
  const StaffSettingsPendingGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final businessSubtitle = session.activeBusinessName != null
        ? 'Business: ${session.activeBusinessName}'
        : '';

    // Determine which settings are still missing for clearer messaging
    final activeBusiness = session.user.businessProfiles.firstWhere(
      (p) => p.businessId == session.activeBusinessId,
      orElse: () => const BusinessProfileInfo(
        businessId: -1,
        businessName: '',
        role: UserRole.staff,
        active: true,
      ),
    );
    final missingEarning = !activeBusiness.earningSettingsConfigured;
    final missingLoyalty = !activeBusiness.loyaltySettingsConfigured;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF1A160A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: DashboardHeader(
                  canSwitchRoles: session.user.canSwitchRoles,
                  activeRoleName: session.activeRole.displayName,
                  subtitle: businessSubtitle,
                  onRoleSwitchTap: () => _switchRole(context, ref, session),
                  onLogoutTap: () => _logout(context, ref),
                ),
              ),
              const SizedBox(height: 32),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFFF59E0B,
                          ).withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.hourglass_top_rounded,
                          color: Color(0xFFF59E0B),
                          size: 48,
                        ),
                      ).animate().scale(
                        duration: 500.ms,
                        curve: Curves.easeOutBack,
                      ),
                      const SizedBox(height: 24),
                      GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFF59E0B,
                                        ).withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.settings_outlined,
                                        color: Color(0xFFF59E0B),
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Setup In Progress',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFFF59E0B),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFF59E0B,
                                    ).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFF59E0B,
                                      ).withValues(alpha: 0.25),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Your business admin hasn\'t finished '
                                          'configuring the loyalty programme yet. '
                                          'Staff features will be available once '
                                          'setup is complete.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: const Color(0xFFF59E0B),
                                                height: 1.5,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),

                                Text(
                                  'Pending configuration:',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),

                                if (missingEarning)
                                  _PendingItem(
                                    icon: Icons.stars_rounded,
                                    title: 'Earning Rules',
                                    subtitle:
                                        'How customers earn loyalty points has not been set up.',
                                  ),
                                if (missingEarning && missingLoyalty)
                                  const SizedBox(height: 10),
                                if (missingLoyalty)
                                  _PendingItem(
                                    icon: Icons.redeem_rounded,
                                    title: 'Loyalty Settings',
                                    subtitle:
                                        'How customers redeem rewards has not been configured.',
                                  ),

                                const SizedBox(height: 24),

                                _InfoRow(
                                  icon: Icons.support_agent_rounded,
                                  text:
                                      'Contact your business admin to complete the setup.',
                                ),
                                const SizedBox(height: 8),
                                _InfoRow(
                                  icon: Icons.notifications_active_outlined,
                                  text:
                                      'You\'ll automatically gain access once setup is finished.',
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.08, end: 0, duration: 400.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    if (session.user.canSwitchRoles)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _switchRole(context, ref, session),
                          icon: const Icon(Icons.swap_horiz_rounded),
                          label: const Text('Switch Role'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    if (session.user.canSwitchRoles) const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryGradientButton(
                        label: 'Log Out',
                        icon: Icons.logout_rounded,
                        onPressed: () => _logout(context, ref),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).logout();
    if (context.mounted) context.go('/login');
  }

  void _switchRole(BuildContext context, WidgetRef ref, Session session) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSelectSheet(
        roles: session.user.roles.toList(),
        businessProfiles: session.user.businessProfiles,
      ),
    ).then((result) {
      if (result != null) {
        final role = result['role'] as UserRole;
        final businessId = result['businessId'] as int?;
        ref
            .read(sessionControllerProvider.notifier)
            .switchRole(
              role,
              businessId: businessId,
              businessName: result['businessName'] as String?,
            );
        final path = switch (role) {
          UserRole.customer => '/customer/dashboard',
          UserRole.businessAdmin => '/business/dashboard',
          UserRole.staff => '/staff/dashboard',
          UserRole.superAdmin => '/admin/dashboard',
        };
        if (context.mounted) context.go(path);
      }
    });
  }
}

class _PendingItem extends StatelessWidget {
  const _PendingItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}
