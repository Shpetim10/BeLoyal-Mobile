import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../auth/presentation/widgets/auth_shell.dart';
import '../../../auth/presentation/widgets/premium_text_field.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../auth/presentation/widgets/status_banner.dart';
import '../../data/models/business_registration_dto.dart';
import '../controllers/business_registration_notifier.dart';
import '../../data/models/submit_application_models.dart';
import '../../../media/data/repositories/media_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

/// Page for entering business registration details.
class BusinessDetailsFormPage extends ConsumerStatefulWidget {
  const BusinessDetailsFormPage({super.key});

  @override
  ConsumerState<BusinessDetailsFormPage> createState() =>
      _BusinessDetailsFormPageState();
}

class _BusinessDetailsFormPageState
    extends ConsumerState<BusinessDetailsFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _businessEmailCtrl = TextEditingController();
  final _businessPhoneCtrl = TextEditingController();
  final _vatIdCtrl = TextEditingController();
  final _websiteUrlCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  // Focus nodes
  final _addressFocus = FocusNode();
  final _cityFocus = FocusNode();
  final _countryFocus = FocusNode();
  final _businessEmailFocus = FocusNode();
  final _businessPhoneFocus = FocusNode();
  final _vatIdFocus = FocusNode();
  final _websiteUrlFocus = FocusNode();
  final _logoUrlFocus = FocusNode();
  final _descriptionFocus = FocusNode();

  BusinessType? _selectedBusinessType;
  RegistrationCurrency? _selectedCurrency;
  File? _logoImage;
  XFile? _pickedLogoXFile;
  final _picker = ImagePicker();
  String? _uploadError;
  bool _isUploadingLogo = false;

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _businessEmailCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _vatIdCtrl.dispose();
    _websiteUrlCtrl.dispose();
    _logoUrlCtrl.dispose();
    _descriptionCtrl.dispose();
    _addressFocus.dispose();
    _cityFocus.dispose();
    _countryFocus.dispose();
    _businessEmailFocus.dispose();
    _businessPhoneFocus.dispose();
    _vatIdFocus.dispose();
    _websiteUrlFocus.dispose();
    _logoUrlFocus.dispose();
    _descriptionFocus.dispose();
    super.dispose();
  }

  String? _validateBusinessType(BusinessType? value) {
    if (value == null) {
      return 'Please select a business type';
    }
    return null;
  }

  String? _validateCurrency(RegistrationCurrency? value) {
    if (value == null) {
      return 'Please select a currency';
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null; // Optional
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme) {
      return 'Enter a valid URL (e.g., https://example.com)';
    }
    return null;
  }

  String? _validateDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'Description must be 1000 characters or less';
    }
    return null;
  }

  Future<void> _pickLogo() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        final ext = picked.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png'].contains(ext)) {
          setState(() => _uploadError = 'Only JPG and PNG files are allowed.');
          return;
        }
        setState(() {
          _logoImage = File(picked.path);
          _pickedLogoXFile = picked;
          _uploadError = null;
        });
      }
    } catch (e) {
      setState(() => _uploadError = 'Failed to pick logo: $e');
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final session = ref.read(sessionControllerProvider);
    final userId =
        session?.user.userId ??
        0; // Fallback if not logged in (new account flow)

    setState(() {
      _isUploadingLogo = true;
      _uploadError = null;
    });

    String? uploadedUrl;
    String? uploadedKey;

    try {
      // 1. Upload logo if selected
      if (_pickedLogoXFile != null) {
        final mediaRepo = ref.read(mediaRepositoryProvider);
        final uploadResult = await mediaRepo.uploadImage(
          file: _pickedLogoXFile!,
          category: 'BUSINESS_LOGO',
          ownerId: userId,
        );
        uploadedUrl = uploadResult['url'];
        uploadedKey = uploadResult['key'];
      }

      // Build business registration DTO
      final businessDto = BusinessRegistrationDto(
        businessName: _businessNameCtrl.text.trim(),
        businessType: _selectedBusinessType!.value,
        currency: _selectedCurrency!.code,
        address: _addressCtrl.text.isEmpty ? null : _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        country: _countryCtrl.text.isEmpty ? null : _countryCtrl.text.trim(),
        businessEmail: _businessEmailCtrl.text.trim().toLowerCase(),
        businessPhoneNumber: _businessPhoneCtrl.text.trim(),
        vatId: _vatIdCtrl.text.isEmpty ? null : _vatIdCtrl.text.trim(),
        websiteUrl: _websiteUrlCtrl.text.isEmpty
            ? null
            : _websiteUrlCtrl.text.trim(),
        logoUrl:
            uploadedUrl ??
            (_logoUrlCtrl.text.isEmpty ? null : _logoUrlCtrl.text.trim()),
        logoKey: uploadedKey,
        businessDescription: _descriptionCtrl.text.isEmpty
            ? null
            : _descriptionCtrl.text.trim(),
      );

      // Store in draft
      ref
          .read(businessRegistrationDraftProvider.notifier)
          .setBusinessRegistrationDto(businessDto);

      // Submit application
      await ref
          .read(submitBusinessApplicationNotifierProvider.notifier)
          .submit();
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadError = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingLogo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitBusinessApplicationNotifierProvider);
    final draft = ref.read(businessRegistrationDraftProvider);

    // Listen for submission success
    ref.listen(submitBusinessApplicationNotifierProvider, (prev, next) {
      next.whenData((response) {
        if (response != null && response.success && mounted) {
          context.go(
            '/business/register/under-review-confirmation',
            extra: {
              'businessName': response.businessName ?? _businessNameCtrl.text,
              'status': response.status ?? 'PENDING_APPROVAL',
            },
          );
        }
      });
    });

    final isLoading = submitState.isLoading;
    final hasError = submitState.hasError;
    final errorMessage = hasError
        ? submitState.error.toString().replaceAll('Exception: ', '')
        : null;

    // Extract field errors from DioException if available
    Map<String, String> fieldErrors = {};
    if (hasError) {
      final error = submitState.error;
      if (error is Exception && error.toString().contains('fieldErrors')) {
        // To be changed when i put field error messages
      }
    }

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
                    'Business Details',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tell us about your business',
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
                          // Error banner
                          if (errorMessage != null) ...[
                            StatusBanner(
                              message: errorMessage,
                              type: StatusBannerType.error,
                              onDismiss: () => ref
                                  .read(
                                    submitBusinessApplicationNotifierProvider
                                        .notifier,
                                  )
                                  .reset(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Business Name (required)
                          PremiumTextField(
                            controller: _businessNameCtrl,
                            label: 'Business Name *',
                            prefixIcon: Icons.storefront_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Business name is required';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_addressFocus),
                          ),
                          const SizedBox(height: 16),

                          // Business Type (required dropdown)
                          DropdownButtonFormField<BusinessType>(
                            value: _selectedBusinessType,
                            decoration: InputDecoration(
                              labelText: 'Business Type *',
                              prefixIcon: const Icon(
                                Icons.category_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            items: BusinessType.values.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedBusinessType = value);
                            },
                            validator: _validateBusinessType,
                          ),
                          const SizedBox(height: 16),

                          // Currency (required dropdown)
                          DropdownButtonFormField<RegistrationCurrency>(
                            value: _selectedCurrency,
                            decoration: InputDecoration(
                              labelText: 'Currency *',
                              prefixIcon: const Icon(
                                Icons.attach_money_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              helperText:
                                  'Cannot be changed after registration',
                              helperStyle: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            items: RegistrationCurrency.values.map((c) {
                              return DropdownMenuItem(
                                value: c,
                                child: Text(c.displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCurrency = value);
                            },
                            validator: _validateCurrency,
                          ),
                          const SizedBox(height: 16),

                          // Address (optional)
                          PremiumTextField(
                            controller: _addressCtrl,
                            label: 'Address',
                            prefixIcon: Icons.location_on_outlined,
                            textInputAction: TextInputAction.next,
                            focusNode: _addressFocus,
                            onFieldSubmitted: (_) =>
                                FocusScope.of(context).requestFocus(_cityFocus),
                          ),
                          const SizedBox(height: 16),

                          // City (required)
                          PremiumTextField(
                            controller: _cityCtrl,
                            label: 'City *',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'City is required';
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                            focusNode: _cityFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_countryFocus),
                          ),
                          const SizedBox(height: 16),

                          // Country (optional)
                          PremiumTextField(
                            controller: _countryCtrl,
                            label: 'Country',
                            prefixIcon: Icons.public_outlined,
                            textInputAction: TextInputAction.next,
                            focusNode: _countryFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_businessEmailFocus),
                          ),
                          const SizedBox(height: 16),

                          // Business Email (required)
                          PremiumTextField(
                            controller: _businessEmailCtrl,
                            label: 'Business Email *',
                            hint: 'business@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: Validators.email,
                            textInputAction: TextInputAction.next,
                            focusNode: _businessEmailFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_businessPhoneFocus),
                          ),
                          const SizedBox(height: 16),

                          // Business Phone (required)
                          PremiumTextField(
                            controller: _businessPhoneCtrl,
                            label: 'Business Phone *',
                            prefixIcon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Business phone is required';
                              }
                              return Validators.phone(v);
                            },
                            textInputAction: TextInputAction.next,
                            focusNode: _businessPhoneFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_vatIdFocus),
                          ),
                          const SizedBox(height: 16),

                          // VAT ID (optional)
                          PremiumTextField(
                            controller: _vatIdCtrl,
                            label: 'VAT ID',
                            prefixIcon: Icons.receipt_long_outlined,
                            textInputAction: TextInputAction.next,
                            focusNode: _vatIdFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_websiteUrlFocus),
                          ),
                          const SizedBox(height: 16),

                          // Website URL (optional)
                          PremiumTextField(
                            controller: _websiteUrlCtrl,
                            label: 'Website URL',
                            hint: 'https://example.com',
                            prefixIcon: Icons.language_outlined,
                            keyboardType: TextInputType.url,
                            validator: _validateUrl,
                            textInputAction: TextInputAction.next,
                            focusNode: _websiteUrlFocus,
                            onFieldSubmitted: (_) => FocusScope.of(
                              context,
                            ).requestFocus(_descriptionFocus),
                          ),
                          const SizedBox(height: 16),

                          // Logo Picker (replaces URL field)
                          Center(child: _buildLogoPicker()),
                          if (_uploadError != null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                _uploadError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),

                          // Business Description (optional, max 1000)
                          TextFormField(
                            controller: _descriptionCtrl,
                            focusNode: _descriptionFocus,
                            decoration: InputDecoration(
                              labelText: 'Business Description',
                              hintText:
                                  'Tell us about your business (max 1000 characters)',
                              prefixIcon: const Icon(
                                Icons.description_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            maxLines: 4,
                            maxLength: 1000,
                            validator: _validateDescription,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _handleSubmit(),
                          ),
                          const SizedBox(height: 24),

                          // Submit button
                          PrimaryGradientButton(
                            label: 'Submit Application',
                            icon: Icons.send_rounded,
                            isLoading: isLoading,
                            onPressed: isLoading ? null : _handleSubmit,
                          ),

                          const SizedBox(height: 16),

                          // Back button
                          TextButton.icon(
                            onPressed: isLoading
                                ? null
                                : () {
                                    final draft = ref.read(
                                      businessRegistrationDraftProvider,
                                    );
                                    if (draft.ownerMode ==
                                        OwnerMode.EXISTING_AUTHENTICATED) {
                                      context.go(
                                        '/business/register/existing-account',
                                      );
                                    } else {
                                      context.go(
                                        '/business/register/new-account',
                                      );
                                    }
                                  },
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

  Widget _buildLogoPicker() {
    return GestureDetector(
      onTap: _isUploadingLogo ? null : _pickLogo,
      child: Stack(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primary.withValues(alpha: 0.1),
              image: _logoImage != null
                  ? DecorationImage(
                      image: FileImage(_logoImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: _logoImage == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 40,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Business Logo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : (_isUploadingLogo
                      ? const Center(child: BesaLoader(size: 24))
                      : null),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(16),
                ),
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
}
