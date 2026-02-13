import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_shell.dart';

class ActivationProcessingPage extends ConsumerStatefulWidget {
  const ActivationProcessingPage({super.key, required this.token});
  final String token;

  @override
  ConsumerState<ActivationProcessingPage> createState() =>
      _ActivationProcessingPageState();
}

class _ActivationProcessingPageState
    extends ConsumerState<ActivationProcessingPage> {
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    // Delay slightly to allow UI to build, then verify.
    Future.microtask(_verifyEmail);
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyEmail(widget.token);

      if (!mounted) return;

      switch (result) {
        case AuthSuccess():
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });
          // Show success for a moment, then navigate.
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) context.go('/login');
          });
        case AuthError(failure: final f):
          setState(() {
            _isLoading = false;
            _errorMessage = f.message;
          });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Icon Animation ──
                _buildIcon(),
                const SizedBox(height: 24),

                // ── Title ──
                Text(
                  _isSuccess
                      ? 'Email Verified!'
                      : _isLoading
                      ? 'Verifying Email...'
                      : 'Verification Failed',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ── Subtitle / Error ──
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  )
                else
                  Text(
                    _isSuccess
                        ? 'Your account is now active. Redirecting to login...'
                        : 'Please wait while we verify your activation token.',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),

                // ── Retry Button (Error only) ──
                if (!_isLoading && !_isSuccess) ...[
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Back to Login'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _verifyEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (_isLoading) {
      return const SizedBox(
        width: 64,
        height: 64,
        child: CircularProgressIndicator(
          color: AppColors.primary,
          strokeWidth: 3,
        ),
      );
    }

    if (_isSuccess) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: AppColors.secondary,
          size: 40,
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.elasticOut);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.error_outline_rounded,
        color: AppColors.error,
        size: 40,
      ),
    ).animate().shake(duration: 400.ms);
  }
}
