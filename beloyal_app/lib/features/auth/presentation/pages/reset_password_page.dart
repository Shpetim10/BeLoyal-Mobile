import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/password_field.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/status_banner.dart';
import '../widgets/password_strength_meter.dart';
import '../controllers/password_reset_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  @override
  void dispose() {
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(passwordResetControllerProvider.notifier)
        .resetPassword(token: widget.token, newPassword: _newPwdCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset Password')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppColors.error),
              const SizedBox(height: 16),
              const Text('Invalid token.', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/login'),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final state = ref.watch(passwordResetControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            ref.read(passwordResetControllerProvider.notifier).clearMessages();
            context.go('/login');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset_rounded,
                size: 80,
                color: AppColors.secondary,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Enter New Password',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 32),

              if (state.errorMessage != null) ...[
                StatusBanner(
                  message: state.errorMessage!,
                  type: StatusBannerType.error,
                  onDismiss: ref
                      .read(passwordResetControllerProvider.notifier)
                      .clearMessages,
                ).animate().fadeIn().slideY(begin: -0.2),
                const SizedBox(height: 24),
              ],
              if (state.isSuccess) ...[
                StatusBanner(
                  message:
                      state.successMessage ?? 'Password successfully changed.',
                  type: StatusBannerType.success,
                  onDismiss: ref
                      .read(passwordResetControllerProvider.notifier)
                      .clearMessages,
                ).animate().fadeIn(),
                const SizedBox(height: 32),
                PrimaryGradientButton(
                  label: 'Proceed to Login',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    ref
                        .read(passwordResetControllerProvider.notifier)
                        .clearMessages();
                    context.go('/login');
                  },
                ).animate().fadeIn(delay: 400.ms),
              ] else ...[
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        PasswordField(
                          controller: _newPwdCtrl,
                          label: 'New Password',
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        PasswordStrengthMeter(controller: _newPwdCtrl),
                        const SizedBox(height: 24),

                        PasswordField(
                          controller: _confirmPwdCtrl,
                          label: 'Confirm Password',
                          validator: Validators.confirmPassword(
                            _newPwdCtrl.text,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),

                        const SizedBox(height: 32),
                        PrimaryGradientButton(
                          label: 'Change Password',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: state.isLoading,
                          onPressed: state.isLoading ? null : _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
