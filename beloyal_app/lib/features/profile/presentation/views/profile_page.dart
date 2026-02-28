import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';

import '../controllers/profile_controller.dart';
import '../../domain/user_profile.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Use variables to track if fields have been edited
  bool _isDirty = false;

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String? _selectedGender;
  DateTime? _selectedBirthdate;

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
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  void _initFieldsIfNeeded(ProfilePageState state) {
    if (_initialized || state.user == null) return;

    _firstNameCtrl.text = state.user!.firstName;
    _lastNameCtrl.text = state.user!.lastName;
    _usernameCtrl.text = state.user!.username;
    _phoneCtrl.text = state.user!.phoneNumber ?? '';

    if (state.customer != null) {
      _cityCtrl.text = state.customer!.city ?? '';
      _countryCtrl.text = state.customer!.country ?? '';
      _selectedGender = state.customer!.gender;
      _selectedBirthdate = state.customer!.birthdate;
    }

    // Add listeners after setting initial text to avoid immediate dirty state
    _firstNameCtrl.addListener(_markDirty);
    _lastNameCtrl.addListener(_markDirty);
    _usernameCtrl.addListener(_markDirty);
    _phoneCtrl.addListener(_markDirty);
    _cityCtrl.addListener(_markDirty);
    _countryCtrl.addListener(_markDirty);

    _initialized = true;
  }

  Future<void> _handleSave(ProfilePageState state) async {
    if (!_formKey.currentState!.validate()) return;

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final controller = ref.read(profileControllerProvider.notifier);

    // Save user profile
    await controller.updateUserProfile(
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      username: _usernameCtrl.text,
      phoneNumber: _phoneCtrl.text.isEmpty ? null : _phoneCtrl.text,
      clearPhoneNumber:
          _phoneCtrl.text.isEmpty && state.user?.phoneNumber != null,
    );

    // Check if error after user save
    final newState = ref.read(profileControllerProvider);
    if (!newState.hasValue || newState.value?.errorMessage != null) {
      return; // Stop if user save failed
    }

    // Save customer profile if they have one
    if (state.customer != null ||
        (ref
                .read(sessionControllerProvider)
                ?.user
                .roles
                .contains(UserRole.customer) ??
            false)) {
      await controller.updateCustomerProfile(
        city: _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
        country: _countryCtrl.text.isEmpty ? null : _countryCtrl.text,
        gender: _selectedGender,
        birthdate: _selectedBirthdate,
        clearCity: _cityCtrl.text.isEmpty && state.customer?.city != null,
        clearCountry:
            _countryCtrl.text.isEmpty && state.customer?.country != null,
        clearGender: _selectedGender == null && state.customer?.gender != null,
        clearBirthdate:
            _selectedBirthdate == null && state.customer?.birthdate != null,
      );
    }

    // If successful, reset dirty state
    final finalState = ref.read(profileControllerProvider);
    if (finalState.hasValue && finalState.value?.errorMessage == null) {
      setState(() => _isDirty = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  // ── Image Picker ──

  Future<void> _showAvatarOptions(ProfilePageState state) async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              if (state.user?.profileImageUrl != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Remove photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ref.read(profileControllerProvider.notifier).removeAvatar();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );

      if (picked != null) {
        final ext = picked.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only JPG and PNG allowed'),
              backgroundColor: AppColors.error,
            ),
          );
          return;
        }
        ref.read(profileControllerProvider.notifier).uploadAvatar(picked);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick image: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthdate ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && picked != _selectedBirthdate) {
      setState(() {
        _selectedBirthdate = picked;
        _isDirty = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);
    final session = ref.watch(sessionControllerProvider);

    // Error banner listener
    ref.listen(profileControllerProvider, (prev, next) {
      if (next.hasValue && next.value?.errorMessage != null) {
        // We use InlineAlert inside the view, so we don't necessarily need a snackbar
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: profileState.when(
        data: (state) {
          _initFieldsIfNeeded(state);

          if (state.user == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Failed to load profile',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage ?? 'Unknown error occurred',
                    style: const TextStyle(color: AppColors.error),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(profileControllerProvider.notifier)
                        .refreshProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final isCustomer =
              session?.user.roles.contains(UserRole.customer) ?? false;
          final isProfileComplete =
              session?.user.customerProfileComplete ?? false;
          final showCustomerSection = isCustomer || isProfileComplete;

          return Form(
            key: _formKey,
            onChanged: _markDirty,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    children: [
                      // Section A: Profile Header
                      _buildProfileHeader(state)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, duration: 400.ms),
                      const SizedBox(height: 24),

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

                      // Section B: Account Details
                      _buildAccountDetails(state)
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                      const SizedBox(height: 24),

                      // Section C: Customer Profile
                      if (showCustomerSection) ...[
                        _buildCustomerDetails(state)
                            .animate()
                            .fadeIn(delay: 200.ms, duration: 400.ms)
                            .slideY(begin: 0.05, end: 0, duration: 400.ms),
                        const SizedBox(height: 24),
                      ],

                      // Section D: Security
                      _buildSecuritySection()
                          .animate()
                          .fadeIn(delay: 300.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0, duration: 400.ms),
                    ],
                  ),
                ),

                // Section E: Save Bar (Sticky Bottom)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ).copyWith(
                          bottom: MediaQuery.of(context).padding.bottom + 16,
                        ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).scaffoldBackgroundColor.withValues(alpha: 0.9),
                      border: const Border(
                        top: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                    child: PrimaryGradientButton(
                      label: 'Save Changes',
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
        loading: () => _buildSkeletonLoading(),
        error: (err, stack) => Center(
          child: StatusBanner(
            message: 'Error: $err',
            type: StatusBannerType.error,
          ),
        ),
      ),
    );
  }

  Widget _buildFallback(UserProfile user) {
    return Center(
      child: Text(
        '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}',
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ProfilePageState state) {
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
                    color: AppColors.primary.withValues(alpha: 0.3),
                    width: 2,
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
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    size: 16,
                    color: AppColors.textMuted,
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
        Text('@${user.username}', style: TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: 12),
        // Terms accepted badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: user.acceptedTerms
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.warning.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: user.acceptedTerms
                  ? AppColors.secondary.withValues(alpha: 0.3)
                  : AppColors.warning.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                user.acceptedTerms
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                size: 14,
                color: user.acceptedTerms
                    ? AppColors.secondary
                    : AppColors.warning,
              ),
              const SizedBox(width: 6),
              Text(
                'Terms accepted',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: user.acceptedTerms
                      ? AppColors.secondary
                      : AppColors.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountDetails(ProfilePageState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Account Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Email (Read-only)
              PremiumTextField(
                controller: TextEditingController(text: state.user!.email),
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PremiumTextField(
                      controller: _lastNameCtrl,
                      label: 'Last name',
                      validator: Validators.name,
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
              ),
              const SizedBox(height: 16),

              PremiumTextField(
                controller: _phoneCtrl,
                label: 'Phone number (optional)',
                prefixIcon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerDetails(ProfilePageState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Customer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.customer == null) ...[
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Customer details not available',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: PremiumTextField(
                        controller: _cityCtrl,
                        label: 'City (optional)',
                        prefixIcon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PremiumTextField(
                        controller: _countryCtrl,
                        label: 'Country (optional)',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Gender (optional)',
                    prefixIcon: const Icon(Icons.wc_rounded, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MALE', child: Text('Male')),
                    DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                    DropdownMenuItem(
                      value: 'PREFER_NOT_TO_SAY',
                      child: Text('Prefer not to say'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != _selectedGender) {
                      setState(() {
                        _selectedGender = val;
                        _isDirty = true;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Birthdate Picker
                InkWell(
                  onTap: _pickBirthdate,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Birthdate (optional)',
                      prefixIcon: const Icon(Icons.cake_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      _selectedBirthdate != null
                          ? '${_selectedBirthdate!.year}-${_selectedBirthdate!.month.toString().padLeft(2, '0')}-${_selectedBirthdate!.day.toString().padLeft(2, '0')}'
                          : 'Tap to select',
                      style: TextStyle(
                        color: _selectedBirthdate != null
                            ? null
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Read-only referrals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Column(
                    children: [
                      _buildReadOnlyRow(
                        'Referral Code',
                        state.customer!.referralCode ?? '—',
                        icon: Icons.copy_rounded,
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.glassBorder, height: 1),
                      const SizedBox(height: 12),
                      _buildReadOnlyRow(
                        'Referred By',
                        state.customer!.referredBy ?? '—',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(String label, String value, {IconData? icon}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 16, color: AppColors.primary),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        GlassCard(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_rounded, color: AppColors.primary),
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Update your security credentials',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
            ),
            onTap: () => context.push('/profile/change-password'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.3, end: 0.7),
          const SizedBox(height: 16),
          Container(
            width: 150,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
          const SizedBox(height: 32),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(24),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(),
        ],
      ),
    );
  }
}
