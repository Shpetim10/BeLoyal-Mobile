import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';

import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../../auth/presentation/widgets/role_chip.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/domain/models/auth_user.dart';

import '../controllers/staff_profile_controller.dart';
import '../widgets/section_card_widget.dart';
import '../widgets/readonly_field_row.dart';
import '../widgets/membership_card.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class StaffProfilePage extends ConsumerStatefulWidget {
  const StaffProfilePage({super.key});

  @override
  ConsumerState<StaffProfilePage> createState() => _StaffProfilePageState();
}

class _StaffProfilePageState extends ConsumerState<StaffProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isInit = false;
  bool _isDirty = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  void _initIfNeeded(StaffProfilePageState state) {
    if (_isInit || state.user == null) return;
    _firstNameCtrl.text = state.user!.firstName;
    _lastNameCtrl.text = state.user!.lastName;
    _usernameCtrl.text = state.user!.username;
    _phoneCtrl.text = state.user!.phoneNumber ?? '';

    _firstNameCtrl.addListener(_markDirty);
    _lastNameCtrl.addListener(_markDirty);
    _usernameCtrl.addListener(_markDirty);
    _phoneCtrl.addListener(_markDirty);

    _isInit = true;
  }

  Future<void> _handleSave(StaffProfilePageState state) async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref
        .read(staffProfileControllerProvider.notifier)
        .updateUserProfile(
          firstName: _firstNameCtrl.text,
          lastName: _lastNameCtrl.text,
          username: _usernameCtrl.text,
          phoneNumber: _phoneCtrl.text,
          clearPhoneNumber: _phoneCtrl.text.trim().isEmpty,
        );

    final updatedState = ref.read(staffProfileControllerProvider);
    if (!updatedState.requireValue.isSaving &&
        updatedState.requireValue.errorMessage == null) {
      setState(() => _isDirty = false);
      if (mounted && updatedState.requireValue.saveSuccessMessage != null) {
        _showToast(
          updatedState.requireValue.saveSuccessMessage!,
          AppColors.secondary,
        );
        ref.read(staffProfileControllerProvider.notifier).clearMessages();
      }
    }
  }

  void _showToast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  'Take Photo',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.secondary,
                ),
                title: const Text(
                  'Choose from Gallery',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUpload(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ref
                      .read(staffProfileControllerProvider.notifier)
                      .removeAvatar();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      await ref
          .read(staffProfileControllerProvider.notifier)
          .uploadAvatar(picked);
      final st = ref.read(staffProfileControllerProvider).requireValue;
      if (st.errorMessage != null && mounted) {
        _showToast(st.errorMessage!, AppColors.error);
      } else if (st.saveSuccessMessage != null && mounted) {
        _showToast(st.saveSuccessMessage!, AppColors.secondary);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(staffProfileControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: stateAsync.when(
        data: (state) {
          _initIfNeeded(state);
          if (state.isLoading) return _buildSkeleton();
          if (state.user == null) return _buildError('Failed to load profile.');

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.secondary,
                  onRefresh: () => ref
                      .read(staffProfileControllerProvider.notifier)
                      .refresh(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.errorMessage != null) ...[
                            StatusBanner(
                              message: state.errorMessage!,
                              type: StatusBannerType.error,
                              onDismiss: ref
                                  .read(staffProfileControllerProvider.notifier)
                                  .clearMessages,
                            ),
                            const SizedBox(height: 20),
                          ],

                          // --- Section A: Header ---
                          _buildHeader(state),
                          const SizedBox(height: 32),

                          // --- Section B: Account Details ---
                          _buildAccountDetails(state),
                          const SizedBox(height: 32),

                          // --- Section C: Membership Details ---
                          if (state.membership != null) ...[
                            MembershipCard(membership: state.membership!),
                            const SizedBox(height: 32),
                          ],

                          // --- Section D: Security ---
                          _buildSecuritySection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- Sticky Footer ---
              GlassCard(
                padding: const EdgeInsets.all(20),
                blur: 15,
                child: SafeArea(
                  top: false,
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
          );
        },
        loading: () => _buildSkeleton(),
        error: (err, _) => _buildError(err.toString()),
      ),
    );
  }

  Widget _buildHeader(StaffProfilePageState state) {
    final user = state.user!;
    final pendingAvatar = state.pendingAvatar;

    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _showAvatarOptions,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.glassWhite.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: pendingAvatar != null
                        ? Image.file(
                            File(pendingAvatar.path),
                            fit: BoxFit.cover,
                          )
                        : (user.profileImageUrl != null &&
                              user.profileImageUrl!.isNotEmpty)
                        ? Image.network(
                            user.profileImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _fallbackAvatar(user),
                          )
                        : _fallbackAvatar(user),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceDark,
                        width: 3,
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
          ).animate().scale(
            delay: 100.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),
          const SizedBox(height: 16),
          Text(
            '${user.firstName} ${user.lastName}'.trim(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '@${user.username}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const RoleChip(role: UserRole.staff),
        ],
      ),
    );
  }

  Widget _fallbackAvatar(user) {
    final initials =
        (user.firstName.isNotEmpty ? user.firstName[0] : '') +
        (user.lastName.isNotEmpty ? user.lastName[0] : '');
    return Container(
      color: AppColors.glassWhite.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountDetails(StaffProfilePageState state) {
    return SectionCardWidget(
      title: 'Personal Information',
      icon: Icons.person_outline_rounded,
      children: [
        ReadonlyFieldRow(
          label: 'Email Address',
          value: state.user!.email,
          icon: Icons.email_rounded,
        ),
        const SizedBox(height: 20),
        PremiumTextField(
          controller: _firstNameCtrl,
          label: 'First Name',
          prefixIcon: Icons.badge_outlined,
          validator: Validators.name,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _lastNameCtrl,
          label: 'Last Name',
          prefixIcon: Icons.badge_outlined,
          validator: Validators.name,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _usernameCtrl,
          label: 'Username',
          prefixIcon: Icons.alternate_email_rounded,
          validator: Validators.username,
        ),
        const SizedBox(height: 16),
        PremiumTextField(
          controller: _phoneCtrl,
          label: 'Phone Number',
          prefixIcon: Icons.phone_outlined,
          validator: Validators.phone,
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    final session = ref.watch(sessionControllerProvider);
    final hasCustomerRole =
        session?.user.roles.contains(UserRole.customer) ?? false;

    return SectionCardWidget(
      title: 'Security',
      icon: Icons.security_rounded,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.glassWhite.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
          onTap: () => context.push('/profile/change-password'),
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
                color: AppColors.primary.withValues(alpha: 0.1),
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
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => context.push('/staff/create-customer-profile'),
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
                color: AppColors.error.withValues(alpha: 0.1),
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
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: _showDeleteCustomerAccountDialog,
          ),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Divider(color: AppColors.glassBorder),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 20,
            ),
          ),
          title: const Text(
            'Log Out',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          onTap: () async {
            ref.read(sessionControllerProvider.notifier).logout();
            if (mounted) context.go('/login');
          },
        ),
      ],
    );
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
          'Your staff membership and business data will be preserved. '
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

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white24),
          const SizedBox(height: 40),
          Container(
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.glassWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
              )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: Colors.white24),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
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
                  ref.read(staffProfileControllerProvider.notifier).refresh(),
            ),
          ],
        ),
      ),
    );
  }
}
