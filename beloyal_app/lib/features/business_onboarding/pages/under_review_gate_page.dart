import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass.dart';
import '../../auth/presentation/controllers/session_controller.dart';
import '../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../auth/presentation/widgets/status_banner.dart';
import '../models/submit_application_models.dart';
import '../state/business_registration_notifier.dart';

/// Gate page shown to business owners whose application is under review.
/// Blocks access to business admin features until approved.
class UnderReviewGatePage extends ConsumerWidget {
  const UnderReviewGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshState = ref.watch(refreshBusinessStatusNotifierProvider);

    // Listen for status changes
    ref.listen(refreshBusinessStatusNotifierProvider, (prev, next) {
      next.whenData((status) {
        if (status == BusinessStatus.active && context.mounted) {
          context.go('/business/dashboard');
        }
      });
    });

    final isLoading = refreshState.isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF0F1A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Business Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // ── Status Card ──
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
                              style: Theme.of(context).textTheme.headlineSmall
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
                        label: isLoading ? 'Refreshing...' : 'Refresh Status',
                        icon: Icons.refresh_rounded,
                        isLoading: isLoading,
                        onPressed: isLoading
                            ? null
                            : () => ref
                                  .read(
                                    refreshBusinessStatusNotifierProvider
                                        .notifier,
                                  )
                                  .refresh(),
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
                          // Navigate to support or show contact info
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

                const Spacer(),

                // ── Logout option ──
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      /* await */
                      ref.read(sessionControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
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
            ),
          ),
        ),
      ),
    );
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
