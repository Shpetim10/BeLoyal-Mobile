import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../controllers/register_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/password_field.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/status_banner.dart';
import '../widgets/terms_checkbox.dart';
import '../widgets/password_strength_meter.dart';

/// Premium Registration Page — REQ-02
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // Focus nodes
  final _lastNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _acceptedTc = false;
  bool _tcError = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _lastNameFocus.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passFocus.dispose();
    _confirmPassFocus.dispose();
    super.dispose();
  }

  void _handleRegister() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!_acceptedTc) {
      setState(() => _tcError = true);
    }

    if (!isFormValid || !_acceptedTc) return;

    ref
        .read(registerControllerProvider.notifier)
        .register(
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
          username: _usernameCtrl.text,
          phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
          acceptedTc: _acceptedTc,
        );
  }

  @override
  Widget build(BuildContext context) {
    final regState = ref.watch(registerControllerProvider);
    final isLoading = regState.isLoading;

    // Navigate to check-email on success.
    ref.listen(registerControllerProvider, (prev, next) {
      next.whenData((uiState) {
        if (uiState.isSuccess && mounted) {
          context.go('/check-email', extra: uiState.registeredEmail);
        }
      });
    });

    final errorMessage = regState.value?.errorMessage;

    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Hero Header ──
                  _HeroHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.15, end: 0, duration: 600.ms),

                  const SizedBox(height: 28),

                  // ── Form Card ──
                  GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Create account',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Join the rewards community',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                              const SizedBox(height: 24),

                              // Error banner
                              if (errorMessage != null) ...[
                                StatusBanner(
                                  message: errorMessage,
                                  onDismiss: () => ref
                                      .read(registerControllerProvider.notifier)
                                      .clearError(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // ── Name row ──
                              Row(
                                children: [
                                  Expanded(
                                    child: PremiumTextField(
                                      controller: _firstNameCtrl,
                                      label: 'First name',
                                      prefixIcon: Icons.person_outline_rounded,
                                      validator: Validators.name,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_lastNameFocus),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: PremiumTextField(
                                      controller: _lastNameCtrl,
                                      label: 'Last name',
                                      validator: Validators.name,
                                      textInputAction: TextInputAction.next,
                                      focusNode: _lastNameFocus,
                                      onFieldSubmitted: (_) => FocusScope.of(
                                        context,
                                      ).requestFocus(_usernameFocus),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Username
                              PremiumTextField(
                                controller: _usernameCtrl,
                                label: 'Username',
                                prefixIcon: Icons.alternate_email_rounded,
                                validator: Validators.username,
                                textInputAction: TextInputAction.next,
                                focusNode: _usernameFocus,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_emailFocus),
                              ),
                              const SizedBox(height: 16),

                              // Email
                              PremiumTextField(
                                controller: _emailCtrl,
                                label: 'Email',
                                hint: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                validator: Validators.email,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                focusNode: _emailFocus,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_phoneFocus),
                              ),
                              const SizedBox(height: 16),

                              // Phone (optional)
                              PremiumTextField(
                                controller: _phoneCtrl,
                                label: 'Phone (optional)',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                validator: Validators.phone,
                                textInputAction: TextInputAction.next,
                                focusNode: _phoneFocus,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_passFocus),
                              ),
                              const SizedBox(height: 16),

                              // Password
                              PasswordField(
                                controller: _passCtrl,
                                label: 'Password',
                                hint:
                                    'Min 8 chars, upper, lower, digit, special',
                                validator: Validators.password,
                                textInputAction: TextInputAction.next,
                                focusNode: _passFocus,
                                onFieldSubmitted: (_) => FocusScope.of(
                                  context,
                                ).requestFocus(_confirmPassFocus),
                              ),
                              const SizedBox(height: 16),
                              PasswordStrengthMeter(controller: _passCtrl),
                              const SizedBox(height: 16),

                              // Confirm Password
                              PasswordField(
                                controller: _confirmPassCtrl,
                                label: 'Confirm password',
                                validator: Validators.confirmPassword(
                                  _passCtrl.text,
                                ),
                                textInputAction: TextInputAction.done,
                                focusNode: _confirmPassFocus,
                                onFieldSubmitted: (_) => _handleRegister(),
                              ),
                              const SizedBox(height: 20),

                              // T&C
                              TermsCheckbox(
                                value: _acceptedTc,
                                error: _tcError,
                                onChanged: (v) {
                                  setState(() {
                                    _acceptedTc = v ?? false;
                                    if (_acceptedTc) _tcError = false;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),

                              // Submit
                              PrimaryGradientButton(
                                label: 'Create Account',
                                icon: Icons.person_add_rounded,
                                isLoading: isLoading,
                                onPressed: isLoading ? null : _handleRegister,
                              ),
                            ],
                          ),
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, duration: 500.ms),

                  const SizedBox(height: 24),

                  // Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Sign In'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),

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

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Hero(
          tag: 'besahub-logo',
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/images/besahub_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'B',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Hero(
          tag: 'besahub-title',
          child: Material(
            color: Colors.transparent,
            child: Text(
              'BesaHub',
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}
