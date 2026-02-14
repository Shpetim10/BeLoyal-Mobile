import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/session_controller.dart';
import '../../../../core/theme/glass.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../widgets/auth_shell.dart';

class ActivationProcessingPage extends ConsumerStatefulWidget {
  const ActivationProcessingPage({super.key, required this.token});
  final String token;

  @override
  ConsumerState<ActivationProcessingPage> createState() =>
      ActivationProcessingPageState();
}

class ActivationProcessingPageState
    extends ConsumerState<ActivationProcessingPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _errorCode;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_verifyEmail);
  }

  Future<void> _verifyEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _errorCode = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.verifyEmail(widget.token);

      if (!mounted) return;

      switch (result) {
        case AuthSuccess(:final data):
          // Save the session with JWT token
          await ref.read(sessionControllerProvider.notifier).setSession(data);

          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          // Show success message briefly
          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;

          // Navigate based on profile status
          if (data.customerProfileComplete) {
            // Profile already complete → Dashboard
            context.go('/customer/dashboard');
          } else {
            // Need to complete profile
            context.go('/create-profile');
          }

        case AuthError(:final failure):
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
            _errorCode = failure.errorCode;
          });

          // Auto-redirect to appropriate page after showing error
          if (failure.errorCode == 'TOKEN_EXPIRED') {
            // Give user time to read the error
            await Future.delayed(const Duration(seconds: 3));
            if (!mounted) return;

            // Extract email from token to pre-fill
            final email = _getEmailFromToken(widget.token);
            context.go('/resend-verification', extra: email);
          }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'An unexpected error occurred';
        });
      }
    }
  }

  String? _getEmailFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      return payloadMap['sub'] as String?;
    } catch (e) {
      return null;
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
                _buildIcon(),
                const SizedBox(height: 24),

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
                        ? 'Redirecting you to complete your profile...'
                        : 'Please wait while we verify your email.',
                    style: TextStyle(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),

                // Action buttons for errors
                if (!_isLoading && !_isSuccess) ...[
                  const SizedBox(height: 24),

                  if (_errorCode == 'TOKEN_EXPIRED')
                    ElevatedButton(
                      onPressed: () {
                        final email = _getEmailFromToken(widget.token);
                        context.go('/resend-verification', extra: email);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Request New Link'),
                    )
                  else
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
