import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass.dart';
import '../../../core/utils/validators.dart';
import '../../auth/presentation/widgets/auth_shell.dart';
import '../../auth/presentation/widgets/password_field.dart';
import '../../auth/presentation/widgets/premium_text_field.dart';
import '../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../auth/presentation/widgets/status_banner.dart';
import '../state/business_registration_notifier.dart';

/// Page for verifying existing account ownership.
class ExistingAccountVerifyPage extends ConsumerStatefulWidget {
  const ExistingAccountVerifyPage({super.key});

  @override
  ConsumerState<ExistingAccountVerifyPage> createState() =>
      _ExistingAccountVerifyPageState();
}

class _ExistingAccountVerifyPageState
    extends ConsumerState<ExistingAccountVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleVerify() {
    if (!_formKey.currentState!.validate()) return;

    ref
        .read(verifyOwnershipNotifierProvider.notifier)
        .verify(_emailCtrl.text, _passwordCtrl.text);
  }

  void _handleContinue() {
    final draft = ref.read(businessRegistrationDraftProvider);
    if (draft.ownershipToken != null && draft.ownershipToken!.isNotEmpty) {
      context.go('/business/register/details');
    }
  }

  @override
  Widget build(BuildContext context) {
    final verifyState = ref.watch(verifyOwnershipNotifierProvider);
    final draft = ref.read(businessRegistrationDraftProvider);

    // Listen for verification success
    ref.listen(verifyOwnershipNotifierProvider, (prev, next) {
      next.whenData((response) {
        if (response != null && response.approved && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Account verified successfully!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      });
    });

    final isLoading = verifyState.isLoading;
    final verifyResponse = verifyState.asData?.value;
    // final hasError = verifyState.hasError;
    final errorMessage = verifyState.hasError
        ? verifyState.error.toString().replaceAll('Exception: ', '')
        : null;

    final canContinue =
        verifyResponse != null &&
        verifyResponse.approved &&
        draft.ownershipToken != null &&
        draft.ownershipToken!.isNotEmpty;

    return AuthShell(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Header ──
                  Text(
                    'Verify Your Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to verify account ownership',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Form Card ──
                  GlassCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Error banner
                          if (errorMessage != null) ...[
                            StatusBanner(
                              message: errorMessage,
                              type: StatusBannerType.error,
                              onDismiss: () => ref
                                  .read(
                                    verifyOwnershipNotifierProvider.notifier,
                                  )
                                  .reset(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email verification warning
                          if (verifyResponse != null &&
                              !verifyResponse.emailVerified) ...[
                            StatusBanner(
                              message:
                                  'Your email is not verified. Please verify your email to continue.',
                              type: StatusBannerType.warning,
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.go(
                                '/resend-verification',
                                extra: _emailCtrl.text,
                              ),
                              icon: const Icon(Icons.email_outlined),
                              label: const Text('Resend Verification Email'),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Success message
                          if (verifyResponse != null &&
                              verifyResponse.approved) ...[
                            StatusBanner(
                              message:
                                  'Account verified! Continue to business details.',
                              type: StatusBannerType.success,
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email field
                          PremiumTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            hint: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                            textInputAction: TextInputAction.next,
                            focusNode: _emailFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_passwordFocus),
                            enabled: !isLoading && !canContinue,
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          PasswordField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            validator: Validators.loginPassword,
                            textInputAction: TextInputAction.done,
                            focusNode: _passwordFocus,
                            onFieldSubmitted: (_) => _handleVerify(),
                          ),
                          const SizedBox(height: 24),

                          // Verify button
                          PrimaryGradientButton(
                            label: 'Verify Account',
                            icon: Icons.verified_outlined,
                            isLoading: isLoading,
                            onPressed: (isLoading || canContinue)
                                ? null
                                : _handleVerify,
                          ),

                          // Continue button (shown after successful verification)
                          if (canContinue) ...[
                            const SizedBox(height: 16),
                            PrimaryGradientButton(
                              label: 'Continue to Business Details',
                              icon: Icons.arrow_forward_rounded,
                              onPressed: _handleContinue,
                            ),
                          ],

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
