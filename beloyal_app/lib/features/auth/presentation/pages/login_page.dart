import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/auth_user.dart';
import '../controllers/login_controller.dart';
import '../controllers/session_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_field.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/status_banner.dart';
import './role_select_sheet.dart';

/// Login Page — REQ-01
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _emailFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref
        .read(loginControllerProvider.notifier)
        .login(_emailCtrl.text, _passCtrl.text);
  }

  void _handleLoginResult(LoginUiState uiState) {
    if (!uiState.isSuccess) return;
    final user = uiState.user!;

    // Step 1: Email not verified -> verification page.
    if (!user.emailVerified) {
      context.go('/check-email', extra: _emailCtrl.text.trim().toLowerCase());
      return;
    }

    // Step 2: Dashboard/Role Selection logic
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

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginControllerProvider);
    final isLoading = loginState.isLoading;

    // React to async state changes.
    ref.listen(loginControllerProvider, (prev, next) {
      next.whenData((uiState) => _handleLoginResult(uiState));
    });

    final errorMessage = loginState.value?.errorMessage;

    return AuthShell(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const _AmbientGlow(
            top: -140,
            left: -110,
            size: 320,
            color: Color(0xFF34D1BF),
          ),
          const _AmbientGlow(
            top: 110,
            right: -110,
            size: 300,
            color: Color(0xFFFFB347),
          ),
          const _AmbientGlow(
            bottom: -150,
            left: 10,
            size: 300,
            color: Color(0xFF8DD7FF),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _HeroHeader()
                    .animate()
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .slideY(begin: -0.15, end: 0, duration: 600.ms),

                const SizedBox(height: 36),
                GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in to continue',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 28),

                        // Error banner
                        if (errorMessage != null) ...[
                          StatusBanner(
                            message: errorMessage,
                            onDismiss: () => ref
                                .read(loginControllerProvider.notifier)
                                .clearError(),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        PremiumTextField(
                          controller: _emailCtrl,
                          label: 'Email',
                          hint: 'you@example.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: Validators.email,
                          autofillHints: const [AutofillHints.email],
                          focusNode: _emailFocus,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).requestFocus(_passFocus),
                        ),
                        const SizedBox(height: 18),

                        // Password
                        PasswordField(
                          controller: _passCtrl,
                          validator: Validators.loginPassword,
                          textInputAction: TextInputAction.done,
                          focusNode: _passFocus,
                          onFieldSubmitted: (_) => _handleLogin(),
                        ),
                        const SizedBox(height: 8),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => context.push('/forgot-password'),
                            child: const Text('Forgot password?'),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Submit
                        PrimaryGradientButton(
                          label: 'Log In',
                          icon: Icons.login_rounded,
                          isLoading: isLoading,
                          onPressed: isLoading ? null : _handleLogin,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.1, end: 0, duration: 500.ms),

                const SizedBox(height: 28),
                _FooterLinks().animate().fadeIn(delay: 400.ms, duration: 500.ms),
              ],
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
        // Logo
        Hero(
          tag: 'besahub-logo',
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/besahub_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Hero(
          tag: 'besahub-title',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'BesaHub',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Loyalty rewarded.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _FooterLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Sign Up'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Own a business?",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            TextButton(
              onPressed: () => context.push('/business/register'),
              child: const Text('Register here'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: math.pi / 5,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                stops: const [0.0, 0.45, 1.0],
                colors: [
                  color.withValues(alpha: 0.18),
                  color.withValues(alpha: 0.06),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
