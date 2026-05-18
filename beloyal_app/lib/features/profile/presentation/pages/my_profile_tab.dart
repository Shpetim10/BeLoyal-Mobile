import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../controllers/profile_controller.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user_profile.dart';
import '../widgets/section_card_widget.dart';

/// "My Profile" tab — shown inside AdminProfileHubPage.
/// Handles first name, last name, username, phone, and avatar.
/// Email is read-only. Change Password navigates to existing page.
class MyProfileTab extends ConsumerStatefulWidget {
  const MyProfileTab({super.key});

  @override
  ConsumerState<MyProfileTab> createState() => _MyProfileTabState();
}

class _MyProfileTabState extends ConsumerState<MyProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _initialized = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initIfNeeded(ProfilePageState state) {
    if (_initialized || state.user == null) return;
    _firstNameCtrl.text = state.user!.firstName;
    _lastNameCtrl.text = state.user!.lastName;
    _usernameCtrl.text = state.user!.username;
    _phoneCtrl.text = state.user!.phoneNumber ?? '';

    _firstNameCtrl.addListener(_markDirty);
    _lastNameCtrl.addListener(_markDirty);
    _usernameCtrl.addListener(_markDirty);
    _phoneCtrl.addListener(_markDirty);
    _initialized = true;
  }

  Future<void> _handleSave(ProfilePageState state) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final controller = ref.read(profileControllerProvider.notifier);
    await controller.updateUserProfile(
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      username: _usernameCtrl.text,
      phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      clearPhoneNumber:
          _phoneCtrl.text.isEmpty && state.user?.phoneNumber != null,
    );

    final newState = ref.read(profileControllerProvider);
    if (newState.hasValue && newState.value?.errorMessage == null) {
      setState(() => _isDirty = false);
      if (mounted) {
        _showToast('Profile saved successfully', AppColors.secondary);
      }
    }
  }

  Future<void> _showAvatarOptions(ProfilePageState state) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Profile Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUpload(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUpload(ImageSource.camera);
                  },
                ),
                if (state.user?.profileImageUrl != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    title: const Text(
                      'Remove photo',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ref
                          .read(profileControllerProvider.notifier)
                          .removeAvatar();
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      final ext = picked.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        if (mounted) {
          _showToast('Only JPG and PNG are allowed', AppColors.error);
        }
        return;
      }
      ref.read(profileControllerProvider.notifier).uploadAvatar(picked);
    } catch (e) {
      if (mounted) {
        _showToast('Failed to pick image: $e', AppColors.error);
      }
    }
  }

  Future<void> _showDeleteCustomerAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Delete Customer Account',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete all your loyalty data including:\n\n'
          '• All loyalty cards and points\n'
          '• All point transactions\n'
          '• All coupon redemptions\n\n'
          'Your business admin membership and business data will be preserved. '
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _deleteCustomerAccount();
  }

  Future<void> _deleteCustomerAccount() async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final result = await profileRepo.deleteCustomerAccount();

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        ref.read(sessionControllerProvider.notifier).removeCustomerRole();
        _showToast('Customer account deleted successfully', AppColors.secondary);
      case AuthError(failure: final f):
        _showToast(f.message, AppColors.error);
    }
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == AppColors.error
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return profileState.when(
      loading: () => _buildSkeleton(),
      error: (err, _) => _buildError(err.toString()),
      data: (state) {
        _initIfNeeded(state);

        if (state.user == null) {
          return _buildError(state.errorMessage ?? 'Failed to load profile');
        }

        final user = state.user!;
        return Form(
          key: _formKey,
          onChanged: _markDirty,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  children: [
                    if (state.errorMessage != null) ...[
                      StatusBanner(
                        message: state.errorMessage!,
                        type: StatusBannerType.error,
                        onDismiss: ref
                            .read(profileControllerProvider.notifier)
                            .clearMessages,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _buildHeader(state)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0, duration: 400.ms),
                    const SizedBox(height: 28),
                    SectionCardWidget(
                          title: 'Account',
                          icon: Icons.manage_accounts_rounded,
                          children: [
                            // Email (read-only)
                            PremiumTextField(
                              controller: TextEditingController(
                                text: user.email,
                              ),
                              label: 'Email',
                              prefixIcon: Icons.email_rounded,
                              readOnly: true,
                              enabled: false,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: PremiumTextField(
                                    controller: _firstNameCtrl,
                                    label: 'First name',
                                    prefixIcon: Icons.person_rounded,
                                    validator: Validators.name,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PremiumTextField(
                                    controller: _lastNameCtrl,
                                    label: 'Last name',
                                    validator: Validators.name,
                                    textInputAction: TextInputAction.next,
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
                            ),
                            const SizedBox(height: 16),

                            PremiumTextField(
                              controller: _phoneCtrl,
                              label: 'Phone number (optional)',
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              validator: Validators.phone,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),
                    Builder(
                      builder: (context) {
                        final session = ref.watch(sessionControllerProvider);
                        final hasCustomerRole =
                            session?.user.roles.contains(UserRole.customer) ??
                            false;
                        return SectionCardWidget(
                          title: 'Security',
                          icon: Icons.security_rounded,
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              title: const Text(
                                'Change Password',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'Update your security credentials',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.textMuted,
                              ),
                              onTap: () =>
                                  context.push('/profile/change-password'),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            if (!hasCustomerRole) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: AppColors.glassBorder),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.loyalty_rounded,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Become a Customer',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: const Text(
                                  'Create a loyalty profile to earn rewards',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                                onTap: () => context.push(
                                  '/staff/create-customer-profile',
                                ),
                              ),
                            ],
                            if (hasCustomerRole) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(color: AppColors.glassBorder),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.person_remove_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Delete Customer Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Remove all loyalty data permanently',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textMuted,
                                ),
                                onTap: _showDeleteCustomerAccountDialog,
                              ),
                            ],
                          ],
                        );
                      },
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).scaffoldBackgroundColor.withValues(alpha: 0.95),
                    border: const Border(
                      top: BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                  child: PrimaryGradientButton(
                    label: 'Save Changes',
                    icon: Icons.save_rounded,
                    isLoading: state.isSaving,
                    onPressed: _isDirty && !state.isSaving
                        ? () => _handleSave(state)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallback(UserProfile user) {
    return Center(
      child: Text(
        '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildHeader(ProfilePageState state) {
    final user = state.user!;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _showAvatarOptions(state),
          child: Stack(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  border: Border.all(
                    color: state.isSaving
                        ? AppColors.primary.withValues(alpha: 0.5)
                        : AppColors.primary.withValues(alpha: 0.25),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: state.pendingAvatar != null
                      ? Image.file(
                          File(state.pendingAvatar!.path),
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) =>
                              _buildFallback(user),
                        )
                      : (user.profileImageUrl != null &&
                                user.profileImageUrl!.isNotEmpty
                            ? Image.network(
                                user.profileImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) =>
                                    _buildFallback(user),
                              )
                            : _buildFallback(user)),
                ),
              ),
              if (state.isSaving)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: const Center(child: BesaLoader(size: 28)),
                  ),
                )
              else
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${user.firstName} ${user.lastName}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username}',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 10),
        // Role badge
        _buildRoleBadge(),
      ],
    );
  }

  Widget _buildRoleBadge() {
    final session = ref.read(sessionControllerProvider);
    final role = session?.activeRole;
    if (role == null) return const SizedBox.shrink();

    final color = role == UserRole.superAdmin
        ? AppColors.accent
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(role.icon, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 6),
          Text(
            role.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        children: [
          // Avatar skeleton
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.glassBorder.withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name skeleton
          Center(
            child: Container(
              width: 160,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.glassBorder.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              onPressed: () =>
                  ref.read(profileControllerProvider.notifier).refreshProfile(),
            ),
          ],
        ),
      ),
    );
  }
}
