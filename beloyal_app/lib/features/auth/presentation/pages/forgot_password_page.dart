import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/status_banner.dart';
import '../controllers/password_reset_controller.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(passwordResetControllerProvider.notifier)
        .forgetPassword(_emailCtrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(
          onPressed: () {
            ref.read(passwordResetControllerProvider.notifier).clearMessages();
            context.pop();
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
                Icons.mark_email_read_rounded,
                size: 80,
                color: AppColors.primary,
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
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
                      state.successMessage ??
                      'Check your email for the reset link.',
                  type: StatusBannerType.success,
                  onDismiss: ref
                      .read(passwordResetControllerProvider.notifier)
                      .clearMessages,
                ).animate().fadeIn(),
                const SizedBox(height: 32),
                PrimaryGradientButton(
                  label: 'Back to Login',
                  icon: Icons.arrow_back_rounded,
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
                        TextFormField(
                          controller: _emailCtrl,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            hintText: 'name@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: AppColors.textMuted.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.done,
                          validator: Validators.email,
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),
                        const SizedBox(height: 32),
                        PrimaryGradientButton(
                          label: 'Send Reset Link',
                          icon: Icons.send_rounded,
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
