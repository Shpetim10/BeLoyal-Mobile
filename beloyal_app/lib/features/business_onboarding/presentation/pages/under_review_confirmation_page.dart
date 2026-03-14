import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';

/// Confirmation page shown after successful business registration submission.
class UnderReviewConfirmationPage extends StatelessWidget {
  const UnderReviewConfirmationPage({
    super.key,
    this.businessName,
    this.status,
  });

  final String? businessName;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final name =
        businessName ?? extra?['businessName'] as String? ?? 'Your Business';
    // final statusValue =
    //     status ?? extra?['status'] as String? ?? 'PENDING_APPROVAL';

    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary,
                              AppColors.secondaryLight,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.secondary.withValues(alpha: 0.3),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 60,
                        ),
                      )
                      .animate()
                      .scale(
                        delay: 200.ms,
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(delay: 200.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                  GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Registration Submitted!',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            StatusBanner(
                              message: 'Status: Under Review',
                              type: StatusBannerType.info,
                            ),
                            const SizedBox(height: 20),

                            Text(
                              'Your business registration has been submitted successfully.',
                              style: Theme.of(context).textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.storefront_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Business Name',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            Text(
                              'What happens next?',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),

                            _NextStepItem(
                              icon: Icons.rate_review_outlined,
                              text: 'Our team will review your application',
                            ),
                            const SizedBox(height: 12),
                            _NextStepItem(
                              icon: Icons.notifications_active_outlined,
                              text:
                                  'You\'ll receive a notification once approved',
                            ),
                            const SizedBox(height: 12),
                            _NextStepItem(
                              icon: Icons.access_time_outlined,
                              text: 'This process may take a few days',
                            ),
                            const SizedBox(height: 24),

                            PrimaryGradientButton(
                              label: 'Go to Dashboard',
                              icon: Icons.dashboard_rounded,
                              onPressed: () =>
                                  context.go('/business/under-review'),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0, duration: 500.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepItem extends StatelessWidget {
  const _NextStepItem({required this.icon, required this.text});

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
