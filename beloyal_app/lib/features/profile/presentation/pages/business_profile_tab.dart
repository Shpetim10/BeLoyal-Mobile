import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../../business_onboarding/data/models/business_registration_dto.dart';
import '../../domain/models/business_profile.dart';
import '../controllers/business_profile_controller.dart';
import '../widgets/logo_picker_widget.dart';
import '../widgets/readonly_field_row.dart';
import '../widgets/section_card_widget.dart';
import '../widgets/status_badge_widget.dart';
import '../../../business_loyalty/presentation/widgets/loyalty_settings_card.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

/// "Restaurant Profile" tab inside AdminProfileHubPage.
/// Restaurant Admin can edit branding, location, contact.
/// VAT ID and Status are read-only for Restaurant Admin.
class BusinessProfileTab extends ConsumerStatefulWidget {
  const BusinessProfileTab({super.key});

  @override
  ConsumerState<BusinessProfileTab> createState() => _BusinessProfileTabState();
}

class _BusinessProfileTabState extends ConsumerState<BusinessProfileTab> {
  final _formKey = GlobalKey<FormState>();
  bool _isDirty = false;
  bool _initialized = false;

  // Editable controllers
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  BusinessType? _selectedType;

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _websiteCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _initIfNeeded(BusinessProfile business) {
    if (_initialized) return;
    _nameCtrl.text = business.businessName;
    _descCtrl.text = business.publicDescription ?? '';
    _addressCtrl.text = business.address ?? '';
    _cityCtrl.text = business.city ?? '';
    _countryCtrl.text = business.country ?? '';
    _websiteCtrl.text = business.websiteUrl ?? '';
    _emailCtrl.text = business.contactEmail ?? '';
    _phoneCtrl.text = business.contactPhone ?? '';
    _selectedType = business.businessType;

    for (final ctrl in [
      _nameCtrl,
      _descCtrl,
      _addressCtrl,
      _cityCtrl,
      _countryCtrl,
      _websiteCtrl,
      _emailCtrl,
      _phoneCtrl,
    ]) {
      ctrl.addListener(_markDirty);
    }

    _initialized = true;
  }

  Future<void> _handleSave(BusinessProfilePageState pageState) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    await ref
        .read(businessProfileControllerProvider.notifier)
        .updateBusiness(
          businessName: _nameCtrl.text.trim(),
          businessType: _selectedType?.value,
          publicDescription: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text,
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text,
          websiteUrl: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text,
          contactEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text,
          contactPhone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text,
        );

    final newState = ref.read(businessProfileControllerProvider);
    if (newState.hasValue && newState.value?.errorMessage == null) {
      setState(() => _isDirty = false);
      if (mounted) _showToast('Restaurant profile saved', AppColors.secondary);
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
    final profileState = ref.watch(businessProfileControllerProvider);

    return profileState.when(
      loading: () => _buildSkeleton(),
      error: (err, _) => _buildError(err.toString()),
      data: (pageState) {
        if (pageState.business == null) {
          if (pageState.errorMessage != null) {
            return _buildError(pageState.errorMessage!);
          }
          return _buildEmptyState();
        }

        _initIfNeeded(pageState.business!);
        final biz = pageState.business!;

        return Form(
          key: _formKey,
          onChanged: _markDirty,
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  children: [
                    // Error banner
                    if (pageState.errorMessage != null) ...[
                      StatusBanner(
                        message: pageState.errorMessage!,
                        type: StatusBannerType.error,
                        onDismiss: ref
                            .read(businessProfileControllerProvider.notifier)
                            .clearMessages,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Builder(
                      builder: (context) {
                        final session = ref.watch(sessionControllerProvider);
                        final profile = session?.user.businessProfiles
                            .firstWhere(
                              (p) => p.businessId == biz.id,
                              orElse: () => session.user.businessProfiles.first,
                            );

                        final earningConfigured =
                            profile?.earningSettingsConfigured ?? false;
                        final earningEnabled =
                            profile?.earningSettingsEnabled ?? false;
                        final loyaltyConfigured =
                            profile?.loyaltySettingsConfigured ?? false;
                        final loyaltyEnabled =
                            profile?.loyaltySettingsEnabled ?? false;

                        return LoyaltySettingsCard(
                              businessId: biz.id,
                              configured: earningConfigured,
                              enabled: earningEnabled,
                              summaryText: earningConfigured
                                  ? 'Active earning rule'
                                  : 'Not set up yet',
                              loyaltyConfigured: loyaltyConfigured,
                              loyaltyEnabled: loyaltyEnabled,
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.07, end: 0, duration: 400.ms);
                      },
                    ),
                    const SizedBox(height: 24),
                    SectionCardWidget(
                          title: 'Branding',
                          icon: Icons.store_rounded,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Logo Picker
                                LogoPickerWidget(
                                  logoUrl: biz.logoPath,
                                  pendingLogo: pageState.pendingLogo,
                                  isUploading: pageState.isUploadingLogo,
                                  businessName: biz.businessName,
                                  onPick: (file) {
                                    _markDirty();
                                    return ref
                                        .read(
                                          businessProfileControllerProvider
                                              .notifier,
                                        )
                                        .uploadLogo(file);
                                  },
                                  onRemove: () {
                                    _markDirty();
                                    ref
                                        .read(
                                          businessProfileControllerProvider
                                              .notifier,
                                        )
                                        .removeLogo();
                                  },
                                ),
                                const SizedBox(width: 20),
                                // Business name + type
                                Expanded(
                                  child: Column(
                                    children: [
                                      PremiumTextField(
                                        controller: _nameCtrl,
                                        label: 'Business name',
                                        prefixIcon: Icons.business_rounded,
                                        validator: Validators.name,
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(height: 14),
                                      _buildTypeDropdown(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.07, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),
                    SectionCardWidget(
                          title: 'Public Info',
                          icon: Icons.info_rounded,
                          children: [
                            TextFormField(
                              controller: _descCtrl,
                              maxLines: 4,
                              maxLength: 500,
                              decoration: InputDecoration(
                                labelText: 'About your business (optional)',
                                hintText:
                                    'Tell customers what makes your business special...',
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                contentPadding: const EdgeInsets.all(16),
                              ),
                              textInputAction: TextInputAction.newline,
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 80.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),
                    SectionCardWidget(
                          title: 'Location',
                          icon: Icons.location_on_rounded,
                          children: [
                            PremiumTextField(
                              controller: _addressCtrl,
                              label: 'Street address (optional)',
                              prefixIcon: Icons.place_rounded,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: PremiumTextField(
                                    controller: _cityCtrl,
                                    label: 'City (optional)',
                                    prefixIcon: Icons.location_city_rounded,
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: PremiumTextField(
                                    controller: _countryCtrl,
                                    label: 'Country (optional)',
                                    textInputAction: TextInputAction.next,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: _websiteCtrl,
                              label: 'Website URL (optional)',
                              prefixIcon: Icons.language_rounded,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              validator: _validateUrl,
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 160.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),
                    SectionCardWidget(
                          title: 'Contact',
                          icon: Icons.contact_phone_rounded,
                          children: [
                            PremiumTextField(
                              controller: _emailCtrl,
                              label: 'Contact email',
                              prefixIcon: Icons.email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return Validators.email(v);
                              },
                            ),
                            const SizedBox(height: 16),
                            PremiumTextField(
                              controller: _phoneCtrl,
                              label: 'Contact phone',
                              prefixIcon: Icons.phone_rounded,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return null;
                                return Validators.phone(v);
                              },
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 240.ms, duration: 400.ms)
                        .slideY(begin: 0.05, end: 0, duration: 400.ms),

                    const SizedBox(height: 24),
                    SectionCardWidget(
                          title: 'Legal & Status',
                          icon: Icons.gavel_rounded,
                          children: [
                            ReadonlyFieldRow(
                              label: 'VAT ID',
                              value: biz.vatId ?? '—',
                              icon: Icons.receipt_long_rounded,
                            ),
                            const SizedBox(height: 12),
                            // Status row with badge
                            Row(
                              children: [
                                Expanded(
                                  child: ReadonlyFieldRow(
                                    label: 'Business Status',
                                    value: '',
                                    showHelper: true,
                                    icon: Icons.verified_rounded,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                StatusBadgeWidget(status: biz.statusDisplay),
                              ],
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 400.ms)
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
                    label: 'Save Restaurant Changes',
                    icon: Icons.save_rounded,
                    isLoading: pageState.isSaving,
                    onPressed:
                        _isDirty &&
                            !pageState.isSaving &&
                            !pageState.isUploadingLogo
                        ? () => _handleSave(pageState)
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

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<BusinessType>(
      value: _selectedType,
      decoration: InputDecoration(
        labelText: 'Business type',
        prefixIcon: const Icon(Icons.category_rounded, size: 20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: BusinessType.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
          .toList(),
      onChanged: (val) {
        if (val != _selectedType) {
          setState(() {
            _selectedType = val;
            _isDirty = true;
          });
        }
      },
    );
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || (!uri.scheme.startsWith('http'))) {
      return 'Enter a valid URL (e.g. https://example.com)';
    }
    return null;
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        children: List.generate(
          5,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                Container(
                  height: i == 0 ? 120 : 56,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ),
        ),
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
              onPressed: () => ref
                  .read(businessProfileControllerProvider.notifier)
                  .refresh(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.store_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No business profile found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your restaurant profile will appear here once your business registration is complete.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
