import 'dart:convert';
import 'package:besahub_app/features/auth/domain/entities/auth_user.dart';
import 'package:besahub_app/features/auth/presentation/views/role_select_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../domain/repositories/auth_repository.dart';
import '../controllers/auth_controller.dart';
import '../controllers/session_controller.dart';
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
      final authController = ref.read(authControllerProvider);
      final result = await authController.completeActivation(widget.token);

      if (!mounted) return;

      switch (result) {
        case AuthSuccess(:final data):
          setState(() {
            _isLoading = false;
            _isSuccess = true;
          });

          await Future.delayed(const Duration(seconds: 2));

          if (!mounted) return;

          AuthUser user= result.data;

          if (user.hasMultipleRoles) {
            _showRoleSheet(user);
          } else {
            // If only one role, pick it. If it's a business role, pick it (even if pending).
            final firstBusiness = user.businessProfiles.firstOrNull;
            if (firstBusiness != null && user.businessProfiles.length == 1) {
              ref
                  .read(sessionControllerProvider.notifier)
                  .establish(
                user,
                firstBusiness.role,
                businessId: firstBusiness.businessId,
                businessName: firstBusiness.businessName,
              );
              _navigateToDashboard(firstBusiness.role);
            } else {
              final role = user.roles.first;

              // Handle Customer Profile Completion check here for single role
              if (role == UserRole.customer && !user.customerProfileComplete) {
                ref.read(sessionControllerProvider.notifier).establish(user, role);
                context.go('/create-profile');
                return;
              }

              ref.read(sessionControllerProvider.notifier).establish(user, role);
              _navigateToDashboard(role);
            }
          }



        case AuthError(:final failure):
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
            _errorCode = failure.errorCode;
          });

          if (failure.errorCode == 'TOKEN_EXPIRED') {
            await Future.delayed(const Duration(seconds: 3));
            if (!mounted) return;
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

  void _showRoleSheet(AuthUser user) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSelectSheet(
        roles: user.roles.toList(),
        businessProfiles: user.businessProfiles,
      ),
    ).then((result) {
      if (result != null && mounted) {
        final role = result['role'] as UserRole;
        final businessId = result['businessId'] as int?;
        final businessName = result['businessName'] as String?;

        // If customer selected and profile incomplete -> /create-profile
        if (role == UserRole.customer && !user.customerProfileComplete) {
          ref
              .read(sessionControllerProvider.notifier)
              .establish(
            user,
            role,
            businessId: businessId,
            businessName: businessName,
          );
          context.go('/create-profile');
          return;
        }

        ref
            .read(sessionControllerProvider.notifier)
            .establish(
          user,
          role,
          businessId: businessId,
          businessName: businessName,
        );
        _navigateToDashboard(role);
      }
    });
  }

  void _navigateToDashboard(UserRole role) {
    final path = switch (role) {
      UserRole.customer => '/customer/dashboard',
      UserRole.businessAdmin => '/business/dashboard',
      UserRole.staff => '/staff/dashboard',
      UserRole.superAdmin => '/admin/dashboard',
    };
    if (mounted) context.go(path);
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
