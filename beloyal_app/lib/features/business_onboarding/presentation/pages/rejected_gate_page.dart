import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/models/session.dart';
import '../../../auth/presentation/pages/role_select_sheet.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Page shown to business owners whose application was rejected.
class RejectedGatePage extends ConsumerWidget {
  const RejectedGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final activeBusiness = session.user.businessProfiles.firstWhere(
      (p) => p.businessId == session.activeBusinessId,
      orElse: () => const BusinessProfileInfo(
        businessId: -1,
        businessName: 'Your Business',
        role: UserRole.customer,
        active: false,
      ),
    );

    final reason =
        activeBusiness.rejectionReason ??
        'Your application did not meet our requirements at this time.';
    final businessSubtitle = 'Business: ${activeBusiness.businessName}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.bgDark,
              Color(0xFF1A0F15),
            ], // Deep dark with subtle red hint
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.cancel_rounded,
                                      color: AppColors.error,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Application Rejected',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        Text(
                                          activeBusiness.businessName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.textMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              StatusBanner(
                                message:
                                    'We were unable to approve your application.',
                                type: StatusBannerType.error,
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Reason for rejection:',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                              ),
                              const SizedBox(height: 12),

                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: Text(
                                  reason,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        height: 1.5,
                                        fontStyle: FontStyle.italic,
                                      ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              Text(
                                'What you can do:',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 16),

                              _ActionItem(
                                icon: Icons.edit_note_rounded,
                                text:
                                    'Review the reason above and update your business data.',
                                onTap: () => context.push(
                                  '/business/rejected/update',
                                  extra: activeBusiness.businessId,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _ActionItem(
                                icon: Icons.support_agent_rounded,
                                text:
                                    'Contact support if you believe this was a mistake.',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Support contact: support@besahub.com',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 32),

                              PrimaryGradientButton(
                                label: 'Update Application',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: () => context.push(
                                  '/business/rejected/update',
                                  extra: activeBusiness.businessId,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 500.ms)
                        .slideY(begin: 0.05, end: 0),
                  ],
                ),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _logout(context, ref),
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Log Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
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
    if (context.mounted) {
      context.go('/login');
    }
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
        context.go(path);
      }
    });
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
