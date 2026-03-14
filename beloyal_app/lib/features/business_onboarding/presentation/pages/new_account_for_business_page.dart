import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/terms_checkbox.dart';
import '../../../auth/presentation/widgets/password_strength_meter.dart';
import '../../data/models/register_user_dto.dart';
import '../controllers/business_registration_notifier.dart';

/// Page for creating a new user account as part of business registration.
class NewAccountForBusinessPage extends ConsumerStatefulWidget {
  const NewAccountForBusinessPage({super.key});

  @override
  ConsumerState<NewAccountForBusinessPage> createState() =>
      _NewAccountForBusinessPageState();
}

class _NewAccountForBusinessPageState
    extends ConsumerState<NewAccountForBusinessPage> {
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

  void _handleContinue() {
    final isFormValid = _formKey.currentState?.validate() ?? false;

    if (!_acceptedTc) {
      setState(() => _tcError = true);
    }

    if (!isFormValid || !_acceptedTc) return;

    // Create user DTO and store in draft
    final userDto = RegisterUserDto(
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      username: _usernameCtrl.text,
      email: _emailCtrl.text,
      phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      password: _passCtrl.text,
      acceptedTc: _acceptedTc,
      acceptedTcVersion: 'v1.0',
    );

    ref.read(businessRegistrationDraftProvider.notifier).setNewUserDto(userDto);

    // Navigate to business details form
    context.go('/business/register/details');
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Create Your Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your account to register your business',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name row
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
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_passFocus),
                          ),
                          const SizedBox(height: 16),

                          // Password
                          PasswordField(
                            controller: _passCtrl,
                            label: 'Password',
                            hint: 'Min 8 chars, upper, lower, digit, special',
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
                            onFieldSubmitted: (_) => _handleContinue(),
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

                          // Continue button
                          PrimaryGradientButton(
                            label: 'Continue',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: _handleContinue,
                          ),

                          const SizedBox(height: 16),

                          // Back button
                          TextButton.icon(
                            onPressed: () =>
                                context.go('/business/register/account-choice'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                        ],
                      ),
                    ),
                  ),

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
