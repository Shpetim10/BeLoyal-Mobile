import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../../data/models/submit_application_models.dart';
import '../controllers/business_registration_notifier.dart';

/// Gate page shown to business owners whose application is under review.
/// Blocks access to business admin features until approved.
class UnderReviewGatePage extends ConsumerWidget {
  const UnderReviewGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final refreshState = ref.watch(refreshBusinessStatusNotifierProvider);

    if (session == null) return const SizedBox.shrink();

    // Listen for status changes
    ref.listen(refreshBusinessStatusNotifierProvider, (prev, next) {
      next.whenData((status) {
        if (status != null &&
            status != BusinessStatus.pendingApproval &&
            context.mounted) {
          context.go('/business/dashboard');
        }
      });
    });

    final isLoading = refreshState.isLoading;
    final businessSubtitle =
        'Business: ${session.activeBusinessName ?? 'Pending'}';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, const Color(0xFF0F1A2E)],
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
                              Icon(
                                Icons.hourglass_empty_rounded,
                                color: AppColors.warning,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Under Review',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          StatusBanner(
                            message:
                                'Your business application is currently under review',
                            type: StatusBannerType.info,
                          ),
                          const SizedBox(height: 20),

                          Text(
                            'Your business registration has been submitted and is being reviewed by our team. '
                            'This process may take a few days.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'What you can expect:',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),

                          _ExpectationItem(
                            icon: Icons.rate_review_outlined,
                            text: 'Our team reviews your business details',
                          ),
                          const SizedBox(height: 12),
                          _ExpectationItem(
                            icon: Icons.verified_outlined,
                            text: 'You\'ll be notified once approved',
                          ),
                          const SizedBox(height: 12),
                          _ExpectationItem(
                            icon: Icons.lock_outline_rounded,
                            text: 'Business features are locked until approval',
                          ),
                          const SizedBox(height: 32),

                          PrimaryGradientButton(
                            label: isLoading
                                ? 'Refreshing...'
                                : 'Refresh Status',
                            icon: Icons.refresh_rounded,
                            isLoading: isLoading,
                            onPressed: isLoading
                                ? null
                                : () {
                                    final session = ref.read(
                                      sessionControllerProvider,
                                    );
                                    final businessId =
                                        session?.activeBusinessId;
                                    if (businessId != null) {
                                      ref
                                          .read(
                                            refreshBusinessStatusNotifierProvider
                                                .notifier,
                                          )
                                          .refresh(businessId);
                                    }
                                  },
                          ),
                          const SizedBox(height: 16),

                          if (refreshState.hasError) ...[
                            StatusBanner(
                              message:
                                  'Failed to refresh status. Please try again.',
                              type: StatusBannerType.error,
                            ),
                            const SizedBox(height: 16),
                          ],

                          OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Contact support feature coming soon',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.support_agent_outlined),
                            label: const Text('Contact Support'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
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

        if (role == UserRole.customer &&
            !session.user.customerProfileComplete) {
          ref.read(sessionControllerProvider.notifier).switchRole(role);
          context.go('/create-profile');
          return;
        }

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

class _ExpectationItem extends StatelessWidget {
  const _ExpectationItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
