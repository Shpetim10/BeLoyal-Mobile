import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/domain/models/session.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/pages/role_select_sheet.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Gate page shown to staff members whose account has been deactivated.
/// Locks out ALL features until re-activated by a Business Admin.
class StaffInactiveGatePage extends ConsumerWidget {
  const StaffInactiveGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final businessSubtitle = session.activeBusinessName != null
        ? 'Business: ${session.activeBusinessName}'
        : '';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, const Color(0xFF1A0F0F)],
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
                          color: AppColors.error.withValues(alpha: 0.12),
                        ),
                        child: const Icon(
                          Icons.block_rounded,
                          color: AppColors.error,
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
                                    const Icon(
                                      Icons.person_off_rounded,
                                      color: AppColors.error,
                                      size: 28,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Account Deactivated',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.error,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.2,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Your staff account has been deactivated by the business admin.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.error,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                Text(
                                  'What this means:',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),

                                _InfoItem(
                                  icon: Icons.lock_rounded,
                                  text:
                                      'All staff features and tools are locked',
                                  color: AppColors.error,
                                ),
                                const SizedBox(height: 10),
                                _InfoItem(
                                  icon: Icons.support_agent_rounded,
                                  text:
                                      'Contact your business admin for more information',
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 10),
                                _InfoItem(
                                  icon: Icons.restore_rounded,
                                  text:
                                      'Access will be restored if your admin re-activates your account',
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.08, end: 0, duration: 400.ms),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: PrimaryGradientButton(
                  label: 'Log Out',
                  icon: Icons.logout_rounded,
                  onPressed: () => _logout(context, ref),
                ),
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

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color == AppColors.error ? AppColors.textOnDark : color,
            ),
          ),
        ),
      ],
    );
  }
}
