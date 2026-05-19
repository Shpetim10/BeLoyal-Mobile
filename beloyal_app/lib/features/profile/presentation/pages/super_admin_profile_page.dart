import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';

import '../controllers/profile_controller.dart';
import '../widgets/readonly_field_row.dart';
import '../../../auth/presentation/widgets/role_chip.dart';
import '../widgets/section_card_widget.dart';

class SuperAdminProfilePage extends ConsumerStatefulWidget {
  const SuperAdminProfilePage({super.key});

  @override
  ConsumerState<SuperAdminProfilePage> createState() =>
      _SuperAdminProfilePageState();
}

class _SuperAdminProfilePageState extends ConsumerState<SuperAdminProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool _isDirty = false;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _initialized = false;

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

  void _initFieldsIfNeeded(ProfilePageState state) {
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
      clearPhoneNumber: _phoneCtrl.text.isEmpty,
    );

    if (mounted &&
        ref.read(profileControllerProvider).value?.isSaving == false) {
      final s = ref.read(profileControllerProvider).value!;
      if (s.saveSuccessMessage != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(s.saveSuccessMessage!)));
        setState(() => _isDirty = false);
      } else if (s.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.errorMessage!),
            backgroundColor: AppColors.error,
          ),
        );
      }
      controller.clearMessages();
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
    );
    if (file == null) return;

    ref.read(profileControllerProvider.notifier).uploadAvatar(file);
  }

  void _removeAvatar() {
    ref.read(profileControllerProvider.notifier).removeAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        title: const Text('Super Admin Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: stateAsync.when(
        loading: () => const Center(child: BesaLoader()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () {
                  ref.read(profileControllerProvider.notifier).refreshProfile();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.user == null) {
            return const Center(child: Text('User details not found.'));
          }
          _initFieldsIfNeeded(state);
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await ref
                        .read(profileControllerProvider.notifier)
                        .refreshProfile();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildHeader(state),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildAccountDetails(state),
                                const SizedBox(height: 24),
                                _buildSecuritySection(),
                                const SizedBox(height: 80), // space for FAB
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: PrimaryGradientButton(
                    label: 'Save Changes',
                    isLoading: state.isSaving,
                    onPressed: _isDirty ? () => _handleSave(state) : null,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(ProfilePageState state) {
    final user = state.user!;
    final isUploading = state.isLoading;
    final pendingFile = state.pendingAvatar;
    final serverUrl = user.profileImageUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.bgDark,
        border: Border(bottom: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          GestureDetector(
            onTap: isUploading ? null : _showAvatarActionSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(pendingFile, serverUrl, user),
                  ),
                ),
                if (isUploading)
                  const Positioned.fill(
                    child: Center(child: BesaLoader(size: 28)),
                  ),
                if (!isUploading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 4, right: 4),
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${user.firstName} ${user.lastName}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          const RoleChip(role: UserRole.superAdmin),
        ],
      ),
    );
  }

  Widget _buildAvatarImage(XFile? pendingFile, String? serverUrl, user) {
    if (pendingFile != null) {
      return Image.file(File(pendingFile.path), fit: BoxFit.cover);
    } else if (serverUrl != null && serverUrl.isNotEmpty) {
      return Image.network(
        serverUrl,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _fallbackAvatar(user),
      );
    }
    return _fallbackAvatar(user);
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

  Widget _buildAccountDetails(ProfilePageState state) {
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.password_rounded, color: AppColors.primary),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            ),
          ),
          subtitle: const Text(
            'Update your credentials',
            style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
          onTap: () {
            context.push('/profile/change-password');
          },
        ),
      ],
    );
  }

  void _showAvatarActionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Profile Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  'Upload from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textOnDark,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickAvatar();
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                  ),
                ),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeAvatar();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
