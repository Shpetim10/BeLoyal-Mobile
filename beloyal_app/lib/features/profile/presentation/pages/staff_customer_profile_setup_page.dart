import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../../media/data/repositories/media_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

class StaffCustomerProfileSetupPage extends ConsumerStatefulWidget {
  const StaffCustomerProfileSetupPage({super.key});

  @override
  ConsumerState<StaffCustomerProfileSetupPage> createState() =>
      _StaffCustomerProfileSetupPageState();
}

class _StaffCustomerProfileSetupPageState
    extends ConsumerState<StaffCustomerProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _referredByCtrl = TextEditingController();

  DateTime? _birthdate;
  String? _selectedGender;
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;
  XFile? _pickedXFile;
  final _picker = ImagePicker();

  static const _genders = [
    {'label': 'Male', 'value': 'MALE'},
    {'label': 'Female', 'value': 'FEMALE'},
    {'label': 'Other', 'value': 'OTHER'},
    {'label': 'Prefer not to say', 'value': 'PREFER_NOT_TO_SAY'},
  ];

  @override
  void dispose() {
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _referredByCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        final ext = picked.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          setState(() => _errorMessage = 'Only JPG and PNG files are allowed.');
          return;
        }
        setState(() {
          _profileImage = File(picked.path);
          _pickedXFile = picked;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to pick image: $e');
    }
  }

  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1920),
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
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = ref.read(sessionControllerProvider);
    if (session == null) {
      setState(() => _errorMessage = 'Session expired. Please log in again.');
      return;
    }

    final businessId = session.activeBusinessId;
    if (businessId == null) {
      setState(() => _errorMessage = 'No active business context. Please re-login.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? uploadedUrl;
    String? uploadedKey;

    try {
      if (_pickedXFile != null) {
        final mediaRepo = ref.read(mediaRepositoryProvider);
        final uploadResult = await mediaRepo.uploadImage(
          file: _pickedXFile!,
          category: 'USER_PROFILE',
          ownerId: session.user.userId,
        );
        uploadedUrl = uploadResult['url'];
        uploadedKey = uploadResult['key'];
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      final result = await profileRepo.createCustomerProfileForStaff(
        businessId: businessId,
        birthdate: _birthdate,
        gender: _selectedGender,
        city: _cityCtrl.text.isEmpty ? null : _cityCtrl.text.trim(),
        country: _countryCtrl.text.isEmpty ? null : _countryCtrl.text.trim(),
        referredBy: _referredByCtrl.text.isEmpty
            ? null
            : _referredByCtrl.text.trim(),
        profileImageUrl: uploadedUrl,
        profileImageKey: uploadedKey,
        notificationEnabled: _notificationsEnabled,
      );

      if (!mounted) return;

      switch (result) {
        case AuthSuccess(data: final dto):
          ref.read(sessionControllerProvider.notifier).completeProfile();
          if (!mounted) return;
          context.go('/loyalty-card-reveal', extra: dto);
        case AuthError(failure: final f):
          setState(() {
            _isLoading = false;
            _errorMessage = f.message;
          });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Become a Customer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            _buildHeader()
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1, end: 0, duration: 500.ms),
            const SizedBox(height: 24),
            GlassCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set up your loyalty profile',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Join loyalty programs across businesses',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      StatusBanner(
                        message: _errorMessage!,
                        onDismiss: () =>
                            setState(() => _errorMessage = null),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Center(child: _buildImagePicker()),
                    const SizedBox(height: 24),
                    _buildDatePicker(),
                    const SizedBox(height: 16),
                    _buildGenderDropdown(),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _cityCtrl,
                      label: 'City (optional)',
                      prefixIcon: Icons.location_city_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _countryCtrl,
                      label: 'Country (optional)',
                      prefixIcon: Icons.public_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _referredByCtrl,
                      label: 'Referral code (optional)',
                      prefixIcon: Icons.card_giftcard_rounded,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 20),
                    _buildNotificationToggle(),
                    const SizedBox(height: 28),
                    PrimaryGradientButton(
                      label: 'Create Customer Profile',
                      icon: Icons.loyalty_rounded,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleSubmit,
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 150.ms, duration: 400.ms)
                .slideY(begin: 0.06, end: 0, duration: 400.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.primaryGradient,
          ),
          child: const Icon(
            Icons.loyalty_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Join the Loyalty World',
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Create your customer profile and start earning rewards',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.1),
              image: _profileImage != null
                  ? DecorationImage(
                      image: FileImage(_profileImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: _profileImage == null
                ? const Icon(Icons.person, size: 50, color: AppColors.primary)
                : null,
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: _pickBirthdate,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Birthdate (optional)',
          prefixIcon: const Icon(Icons.cake_rounded, size: 20),
          suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          _birthdate != null ? _formatDate(_birthdate!) : 'Tap to select',
          style: TextStyle(
            color: _birthdate != null ? null : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender (optional)',
        prefixIcon: const Icon(Icons.wc_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _genders
          .map(
            (g) => DropdownMenuItem(
              value: g['value'],
              child: Text(g['label'] ?? ''),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedGender = val),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withValues(alpha: 0.06),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        title: const Text('Enable notifications'),
        subtitle: Text(
          'Get updates on offers and rewards',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        secondary: const Icon(
          Icons.notifications_active_rounded,
          color: AppColors.primary,
        ),
        value: _notificationsEnabled,
        onChanged: (val) => setState(() => _notificationsEnabled = val),
        activeColor: AppColors.primary,
      ),
    );
  }
}
