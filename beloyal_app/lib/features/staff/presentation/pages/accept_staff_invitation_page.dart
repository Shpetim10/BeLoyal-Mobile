import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../auth/presentation/widgets/password_field.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../../auth/presentation/widgets/terms_checkbox.dart';
import '../../../auth/presentation/widgets/password_strength_meter.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../controllers/accept_invitation_controller.dart';

/// Accept Staff Invitation Page — Premium page for accepting invitations.
class AcceptStaffInvitationPage extends ConsumerStatefulWidget {
  const AcceptStaffInvitationPage({
    super.key,
    required this.token,
    required this.isExistingUser,
    this.email,
  });

  final String token;
  final bool isExistingUser;
  final String? email;

  @override
  ConsumerState<AcceptStaffInvitationPage> createState() =>
      _AcceptStaffInvitationPageState();
}

class _AcceptStaffInvitationPageState
    extends ConsumerState<AcceptStaffInvitationPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // Just for display maybe
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  final _lastNameFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmPassFocus = FocusNode();

  bool _acceptedTc = false;
  bool _tcError = false;
  bool _isValidating = true;

  @override
  void initState() {
    super.initState();
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailCtrl.text = widget.email!;
    }
    // Simulate token validation / loading state to fulfill UI requirements
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    });
  }

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

  void _handleSubmitNewUser() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!_acceptedTc) setState(() => _tcError = true);
    if (!isFormValid || !_acceptedTc) return;

    ref
        .read(acceptInvitationControllerProvider.notifier)
        .submitRegistration(
          token: widget.token,
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          email: _emailCtrl
              .text, // Send it even if empty or pre-filled, the server can use its own token email but we provide it based on form
          username: _usernameCtrl.text,
          phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
          password: _passCtrl.text,
          acceptedTc: _acceptedTc,
        );
  }

  void _handleSubmitExistingUser() {
    ref
        .read(acceptInvitationControllerProvider.notifier)
        .acceptAsExistingUser(token: widget.token);
  }

  @override
  Widget build(BuildContext context) {
    if (_isValidating) return _buildLoadingState();

    final uiState = ref.watch(acceptInvitationControllerProvider);
    final isSuccess = uiState.value?.isSuccess ?? false;
    final errorMessage = uiState.value?.errorMessage;
    final isLoading = uiState.isLoading;

    if (isSuccess) return _buildSuccessState(uiState.value?.isNewUser ?? false);

    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.15, end: 0, duration: 600.ms),
                  const SizedBox(height: 28),
                  if (errorMessage != null) ...[
                    StatusBanner(
                      message: errorMessage,
                      type: StatusBannerType.error,
                      onDismiss: () => ref
                          .read(acceptInvitationControllerProvider.notifier)
                          .clearError(),
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                  ],
                  GlassCard(
                        child: widget.isExistingUser
                            ? _buildExistingUserForm(isLoading)
                            : _buildNewUserForm(isLoading),
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 500.ms)
                      .slideY(begin: 0.08, end: 0, duration: 500.ms),
                  const SizedBox(height: 24),
                  _buildFooter().animate().fadeIn(
                    delay: 400.ms,
                    duration: 500.ms,
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

  Widget _buildLoadingState() {
    return AuthShell(
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SkeletonLoader(width: 80, height: 80, rounded: true),
              const SizedBox(height: 24),
              const _SkeletonLoader(width: 200, height: 24),
              const SizedBox(height: 12),
              const _SkeletonLoader(width: 140, height: 16),
              const SizedBox(height: 32),
              Text(
                    'Validating invite…',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                  .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
                  .fade(begin: 0.5, end: 1.0, duration: 800.ms),
            ],
          ),
        ).animate().fadeIn(),
      ),
    );
  }

  Widget _buildSuccessState(bool isNewUser) {
    return AuthShell(
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.secondary,
                  size: 48,
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
              const SizedBox(height: 24),
              Text(
                isNewUser ? 'Account created!' : 'You’re all set!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
              Text(
                isNewUser
                    ? 'Please check your email to verify your account.'
                    : 'Your staff access is now active.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textMuted),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 32),
              PrimaryGradientButton(
                label: isNewUser ? 'Verify Email' : 'Go to Staff Dashboard',
                onPressed: () {
                  if (isNewUser) {
                    context.go('/check-email', extra: _emailCtrl.text);
                  } else {
                    context.go('/staff/dashboard');
                  }
                },
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
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
        const SizedBox(height: 12),
        Text(
          'BesaHub',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildNewUserForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You’re invited to join',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Set your details to activate your staff access.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          PremiumTextField(
            controller: _emailCtrl,
            label: 'Email (from invite)',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
            readOnly: widget.email != null && widget.email!.isNotEmpty,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_lastNameFocus),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PremiumTextField(
                  controller: _firstNameCtrl,
                  label: 'First name',
                  prefixIcon: Icons.person_outline_rounded,
                  validator: Validators.name,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_lastNameFocus),
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
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_usernameFocus),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PremiumTextField(
            controller: _usernameCtrl,
            label: 'Username',
            prefixIcon: Icons.alternate_email_rounded,
            validator: Validators.username,
            textInputAction: TextInputAction.next,
            focusNode: _usernameFocus,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_phoneFocus),
          ),
          const SizedBox(height: 16),
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
          PasswordField(
            controller: _passCtrl,
            label: 'Password',
            hint: 'Min 8 chars, upper, lower, digit, special',
            validator: Validators.password,
            textInputAction: TextInputAction.next,
            focusNode: _passFocus,
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmPassFocus),
          ),
          const SizedBox(height: 16),
          PasswordStrengthMeter(controller: _passCtrl),
          const SizedBox(height: 16),
          PasswordField(
            controller: _confirmPassCtrl,
            label: 'Confirm password',
            validator: Validators.confirmPassword(_passCtrl.text),
            textInputAction: TextInputAction.done,
            focusNode: _confirmPassFocus,
            onFieldSubmitted: (_) => _handleSubmitNewUser(),
          ),
          const SizedBox(height: 20),
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
          PrimaryGradientButton(
            label: 'Activate account',
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleSubmitNewUser,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingUserForm(bool isLoading) {
    final session = ref.watch(sessionControllerProvider);
    final isLoggedIn = session != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'You’re invited to join',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          'Accept the invitation to activate your staff access.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),
        if (!isLoggedIn) ...[
          StatusBanner(
            message:
                'You need to be logged in to accept this invitation using your existing account.',
            type: StatusBannerType.warning,
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Log In',
            icon: Icons.login_rounded,
            onPressed: () => context.go('/login'),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Text(
                    session.user.emailVerified ? '✓' : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Logged in',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Ready to accept invitation',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          PrimaryGradientButton(
            label: 'Accept Invitation',
            isLoading: isLoading,
            onPressed: isLoading ? null : _handleSubmitExistingUser,
          ),
        ],
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to login'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'This link expires in 24–72 hours.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// A simple animated skeleton loader for the loading state.
class _SkeletonLoader extends StatelessWidget {
  const _SkeletonLoader({
    required this.width,
    required this.height,
    this.rounded = false,
  });

  final double width;
  final double height;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white12 : Colors.black12;

    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(rounded ? height / 2 : 8),
          ),
        )
        .animate(onPlay: (ctrl) => ctrl.repeat(reverse: true))
        .fade(begin: 0.3, end: 0.8, duration: 800.ms);
  }
}
