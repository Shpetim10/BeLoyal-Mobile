import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';

import '../controllers/change_password_controller.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  double _strength = 0.0;
  bool _hasLength = false;
  bool _hasUpperLower = false;
  bool _hasNumberSpecial = false;

  @override
  void initState() {
    super.initState();
    _newPwdCtrl.addListener(_evaluateStrength);
  }

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _evaluateStrength() {
    final pwd = _newPwdCtrl.text;
    bool len = pwd.length >= 8;
    bool ul = RegExp(r'(?=.*[a-z])(?=.*[A-Z])').hasMatch(pwd);
    bool ns = RegExp(r'(?=.*\d)(?=.*[@$!%*?&])').hasMatch(pwd);

    double str = 0;
    if (len) str += 0.33;
    if (ul) str += 0.33;
    if (ns) str += 0.34;

    setState(() {
      _hasLength = len;
      _hasUpperLower = ul;
      _hasNumberSpecial = ns;
      _strength = str;
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to change your password? You will use the new password on your next login.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Yes, Change',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(changePasswordControllerProvider.notifier)
        .changePassword(
          currentPassword: _currentPwdCtrl.text,
          newPassword: _newPwdCtrl.text,
        );

    final state = ref.read(changePasswordControllerProvider);
    if (state.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.successMessage ?? 'Password updated'),
          backgroundColor: AppColors.secondary,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            if (state.errorMessage != null) ...[
              StatusBanner(
                message: state.errorMessage!,
                type: StatusBannerType.error,
                onDismiss: ref
                    .read(changePasswordControllerProvider.notifier)
                    .clearMessages,
              ),
              const SizedBox(height: 16),
            ],

            GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PasswordField(
                          controller: _currentPwdCtrl,
                          label: 'Current Password',
                          validator: Validators.password,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 24),

                        PasswordField(
                          controller: _newPwdCtrl,
                          label: 'New Password',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a valid password';
                            }
                            return null; // The exact validation string handled by the regex/api
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _buildStrengthMeter(),
                        const SizedBox(height: 24),

                        PasswordField(
                          controller: _confirmPwdCtrl,
                          label: 'Confirm New Password',
                          validator: Validators.confirmPassword(
                            _newPwdCtrl.text,
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleSubmit(),
                        ),
                        const SizedBox(height: 32),

                        PrimaryGradientButton(
                          label: 'Update Password',
                          icon: Icons.lock_reset_rounded,
                          isLoading: state.isLoading,
                          onPressed: state.isLoading ? null : _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthMeter() {
    Color getStrColor() {
      if (_strength < 0.4) return AppColors.error;
      if (_strength < 0.7) return AppColors.warning;
      return AppColors.secondary;
    }

    Widget rule(String text, bool met) {
      return Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 14,
            color: met
                ? AppColors.secondary
                : AppColors.textMuted.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: met ? AppColors.textOnDark : AppColors.textMuted,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _strength,
            backgroundColor: AppColors.textMuted.withValues(alpha: 0.2),
            color: getStrColor(),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 12),
        rule('At least 8 characters', _hasLength),
        const SizedBox(height: 4),
        rule('Uppercase & lowercase letters', _hasUpperLower),
        const SizedBox(height: 4),
        rule('Number & special character', _hasNumberSpecial),
      ],
    );
  }
}
