import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../widgets/auth_shell.dart';

/// Check your email page — shown after successful registration.
class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({super.key, this.email});
  final String? email;

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  late final ConfettiController _confetti;
  bool _resendCooldown = false;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    // Short delay then celebrate.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _confetti.play();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  String _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return '***@***.com';
    final parts = email.split('@');
    final name = parts[0];
    final masked = name.length <= 2
        ? '***'
        : '${name[0]}***${name[name.length - 1]}';
    return '$masked@${parts[1]}';
  }

  void _resendEmail() {
    if (_resendCooldown) return;
    setState(() => _resendCooldown = true);

    // Simulate cooldown — real API call would go here.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Verification email resent!'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) setState(() => _resendCooldown = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                const SizedBox(height: 40),
                Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.secondary.withValues(alpha: 0.12),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.secondary,
                        size: 48,
                      ),
                    )
                    .animate()
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 12),

                Text(
                  'We sent a verification link to',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                const SizedBox(height: 8),

                // Masked email
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  borderRadius: 14,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _maskEmail(widget.email),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

                const SizedBox(height: 32),

                Text(
                  'Click the link in your email to verify your account. '
                  "If you don't see it, check your spam folder.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                const SizedBox(height: 36),
                OutlinedButton.icon(
                  onPressed: _resendCooldown ? null : _resendEmail,
                  icon: Icon(
                    _resendCooldown
                        ? Icons.hourglass_top_rounded
                        : Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: Text(
                    _resendCooldown
                        ? 'Resend available in 30s'
                        : 'Resend verification email',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Back to Login'),
                ).animate().fadeIn(delay: 700.ms, duration: 500.ms),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 20,
            maxBlastForce: 15,
            minBlastForce: 5,
            gravity: 0.15,
            colors: const [
              AppColors.primary,
              AppColors.accent,
              AppColors.secondary,
              AppColors.primaryLight,
              AppColors.accentLight,
            ],
          ),
        ],
      ),
    );
  }
}
