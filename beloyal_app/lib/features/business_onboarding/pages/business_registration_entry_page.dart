import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass.dart';
import '../../auth/presentation/widgets/auth_shell.dart';
import '../../auth/presentation/widgets/primary_gradient_button.dart';

/// Entry page for business registration flow.
/// Explains the process and provides entry point.
class BusinessRegistrationEntryPage extends StatelessWidget {
  const BusinessRegistrationEntryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Hero Header ──
                  _HeroHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.15, end: 0, duration: 600.ms),

                  const SizedBox(height: 32),

                  // ── Info Card ──
                  GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                    'Register your Business',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Join BesaHub as a business partner and start rewarding your customers.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            _InfoItem(
                              icon: Icons.check_circle_outline_rounded,
                              text: 'Quick registration process',
                            ),
                            const SizedBox(height: 12),
                            _InfoItem(
                              icon: Icons.verified_outlined,
                              text: 'Admin review and approval',
                            ),
                            const SizedBox(height: 12),
                            _InfoItem(
                              icon: Icons.notifications_active_outlined,
                              text: 'You\'ll be notified once approved',
                            ),
                            const SizedBox(height: 24),
                            PrimaryGradientButton(
                              label: 'Start Business Registration',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: () => context.go(
                                '/business/register/account-choice',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              child: const Text('Back to Login'),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, duration: 500.ms),

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

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.business_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Business Registration',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
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
