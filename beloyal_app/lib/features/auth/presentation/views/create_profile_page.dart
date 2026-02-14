import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../controllers/session_controller.dart';
import '../widgets/auth_shell.dart';
import '../widgets/premium_text_field.dart';
import '../widgets/primary_gradient_button.dart';
import '../widgets/status_banner.dart';
import '../../data/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Premium Create Profile Page — shown after login if profile is not complete.
class CreateProfilePage extends ConsumerStatefulWidget {
  const CreateProfilePage({super.key});

  @override
  ConsumerState<CreateProfilePage> createState() => _CreateProfilePageState();
}

class _CreateProfilePageState extends ConsumerState<CreateProfilePage> {
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
  final _picker = ImagePicker();

  static const _genders = [
    {'label': 'Male', 'value': 'MALE'},
    {'label': 'Female', 'value': "FEMALE"},
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
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        final ext = picked.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          setState(() => _errorMessage = 'Only JPG and PNG files are allowed.');
          return;
        }
        setState(() {
          _profileImage = File(picked.path);
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
    if (picked != null) {
      setState(() => _birthdate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final session = ref.read(sessionControllerProvider);
    if (session == null) {
      setState(() => _errorMessage = 'Session expired. Please log in again.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    String? localImagePath;

    // 1. Copy image to local app directory if selected
    if (_profileImage != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(_profileImage!.path);
        // Copy to app documents directory
        final savedImage = await _profileImage!.copy(
          '${directory.path}/$fileName',
        );
        localImagePath = savedImage.path;
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to save image locally: $e';
        });
        return;
      }
    }

    final repo = ref.read(authRepositoryProvider);
    // Updated to pass path string instead of File
    final result = await repo.createCustomerProfile(
      token: session.token,
      birthdate: _birthdate,
      gender: _selectedGender,
      city: _cityCtrl.text.isEmpty ? null : _cityCtrl.text.trim(),
      country: _countryCtrl.text.isEmpty ? null : _countryCtrl.text.trim(),
      referredBy: _referredByCtrl.text.isEmpty
          ? null
          : _referredByCtrl.text.trim(),
      profileImagePath: localImagePath,
      notificationEnabled: _notificationsEnabled,
    );

    if (!mounted) return;

    switch (result) {
      case AuthSuccess():
        // Navigate to Onboarding Success page first
        context.go('/onboarding-success');
      case AuthError(failure: final f):
        setState(() {
          _isLoading = false;
          _errorMessage = f.message;
        });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            const SizedBox(height: 24),

            // ── Header ──
            _buildHeader()
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
                          'Complete your profile',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tell us a bit about yourself',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 24),

                        // Error banner
                        if (_errorMessage != null) ...[
                          StatusBanner(
                            message: _errorMessage!,
                            onDismiss: () =>
                                setState(() => _errorMessage = null),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // ── Profile Image Picker ──
                        Center(child: _buildImagePicker()),
                        const SizedBox(height: 24),

                        // ── Birthdate ──
                        _buildDatePicker(),
                        const SizedBox(height: 16),

                        // ── Gender ──
                        _buildGenderDropdown(),
                        const SizedBox(height: 16),

                        // ── City ──
                        PremiumTextField(
                          controller: _cityCtrl,
                          label: 'City (optional)',
                          prefixIcon: Icons.location_city_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // ── Country ──
                        PremiumTextField(
                          controller: _countryCtrl,
                          label: 'Country (optional)',
                          prefixIcon: Icons.public_rounded,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),

                        // ── Referred by ──
                        PremiumTextField(
                          controller: _referredByCtrl,
                          label: 'Referral code (optional)',
                          prefixIcon: Icons.card_giftcard_rounded,
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 20),

                        // ── Notifications toggle ──
                        _buildNotificationToggle(),
                        const SizedBox(height: 28),

                        // ── Submit ──
                        PrimaryGradientButton(
                          label: 'Save Profile',
                          icon: Icons.check_circle_outline_rounded,
                          isLoading: _isLoading,
                          onPressed: _isLoading ? null : _handleSubmit,
                        ),
                      ],
                    ),
                  ),
                )
                .animate()
                .fadeIn(delay: 200.ms, duration: 500.ms)
                .slideY(begin: 0.08, end: 0, duration: 500.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
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

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withValues(alpha: 0.12),
          ),
          child: const Icon(
            Icons.person_outline_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Almost there!',
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Set up your profile to get started',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ],
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
