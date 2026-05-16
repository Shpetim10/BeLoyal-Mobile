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

/// Page shown to business owners whose business has been suspended/made inactive.
class SuspendedGatePage extends ConsumerWidget {
  const SuspendedGatePage({super.key});

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

    final businessSubtitle = 'Business: ${activeBusiness.businessName}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF1A1510)],
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
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.pause_circle_rounded,
                                    color: AppColors.warning,
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
                                        'Business Suspended',
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
                                  'Your business is currently suspended and cannot operate.',
                              type: StatusBannerType.warning,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'What does this mean?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
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
                              child: const Text(
                                'Your business account has been temporarily suspended. During this period, customers cannot see your business, and transactions cannot be processed. Historical data remains accessible.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Next steps',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(
                                  alpha: 0.08,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.2,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Please contact our support team to understand why your business was suspended and what actions you can take to restore it.',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    PrimaryGradientButton(
                      label: 'Contact Support',
                      onPressed: () {
                        // TODO: Open support contact or email
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _logout(context, ref),
                        child: const Text('Logout'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      if (result == null || !context.mounted) return;
      final role = result['role'] as UserRole;
      final businessId = result['businessId'] as int?;
      ref
          .read(sessionControllerProvider.notifier)
          .switchRole(
            role,
            businessId: businessId,
            businessName: result['businessName'] as String?,
          );
    });
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}
