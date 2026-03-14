import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:confetti/confetti.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/session_controller.dart';
import '../widgets/auth_shell.dart';
import '../../../../core/theme/glass.dart';
import '../../domain/models/auth_user.dart';

class OnboardingSuccessPage extends ConsumerStatefulWidget {
  const OnboardingSuccessPage({super.key});

  @override
  ConsumerState<OnboardingSuccessPage> createState() =>
      _OnboardingSuccessPageState();
}

class _OnboardingSuccessPageState extends ConsumerState<OnboardingSuccessPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();

    // Auto-redirect after a few seconds
    Future.delayed(const Duration(seconds: 4), _goToDashboard);
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goToDashboard() {
    if (!mounted) return;
    final session = ref.read(sessionControllerProvider);
    if (session == null) {
      context.go('/login');
      return;
    }

    final role = session.activeRole;
    final path = switch (role) {
      UserRole.customer => '/customer/dashboard',
      UserRole.businessAdmin => '/business/dashboard',
      UserRole.staff => '/staff/dashboard',
      UserRole.superAdmin => '/admin/dashboard',
    };
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.secondary,
                        size: 48,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 24),

                    Text(
                          'All Set!',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        )
                        .animate()
                        .fadeIn(delay: 200.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: 12),

                    Text(
                      'Your profile has been created successfully.\nWelcome to BesaHub.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _goToDashboard,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Go to Dashboard'),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppColors.primary,
                AppColors.secondary,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
