import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../controllers/business_registration_notifier.dart';
import '../../data/models/submit_application_models.dart';

/// Account choice page: existing account vs new account.
class BusinessAccountChoicePage extends ConsumerWidget {
  const BusinessAccountChoicePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                        'Do you already have an account?',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.1, end: 0, duration: 400.ms),

                  const SizedBox(height: 8),
                  Text(
                    'Choose how you want to proceed',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                  const SizedBox(height: 40),
                  _ChoiceCard(
                        icon: Icons.person_rounded,
                        title: 'I already have an account',
                        description: 'Sign in with your existing credentials',
                        onTap: () {
                          ref
                              .read(businessRegistrationDraftProvider.notifier)
                              .setOwnerMode(OwnerMode.EXISTING_AUTHENTICATED);
                          context.go('/business/register/existing-account');
                        },
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideX(begin: -0.1, end: 0, duration: 500.ms),

                  const SizedBox(height: 16),

                  _ChoiceCard(
                        icon: Icons.person_add_rounded,
                        title: 'I\'m new to BesaHub',
                        description: 'Create a new account for your business',
                        onTap: () {
                          ref
                              .read(businessRegistrationDraftProvider.notifier)
                              .setOwnerMode(OwnerMode.NEW_ACCOUNT);
                          context.go('/business/register/new-account');
                        },
                      )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideX(begin: 0.1, end: 0, duration: 500.ms),

                  const SizedBox(height: 32),
                  TextButton.icon(
                    onPressed: () => context.go('/business/register'),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back'),
                  ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

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

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: GlassCard(
        borderRadius: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
