import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/controllers/business_profile_controller.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_lookup_models.dart';
import '../controllers/coupon_create_controller.dart';
import '../controllers/coupon_list_controller.dart';
import '../widgets/coupon_preview_card.dart';
import '../widgets/coupon_status_chip.dart';

class CouponCreatePage extends ConsumerStatefulWidget {
  const CouponCreatePage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponCreatePage> createState() => _CouponCreatePageState();
}

class _CouponCreatePageState extends ConsumerState<CouponCreatePage> {
  final _step1FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();
  final _step4FormKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _discountPctCtrl = TextEditingController();
  final _discountAmtCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxDiscountCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _totalLimitCtrl = TextEditingController();
  final _perCustomerLimitCtrl = TextEditingController();
  final _sortOrderCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(couponCreateControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _termsCtrl.dispose();
    _pointsCtrl.dispose();
    _discountPctCtrl.dispose();
    _discountAmtCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxDiscountCtrl.dispose();
    _quantityCtrl.dispose();
    _totalLimitCtrl.dispose();
    _perCustomerLimitCtrl.dispose();
    _sortOrderCtrl.dispose();
    super.dispose();
  }

  void _resetFormForType() {
    final ctrl = ref.read(couponCreateControllerProvider.notifier);
    ctrl.updateDiscountFields(
      discountPercentage: '',
      discountAmount: '',
      minimumOrderAmount: '',
      maximumDiscountAmount: '',
      quantity: '1',
    );
    _discountPctCtrl.clear();
    _discountAmtCtrl.clear();
    _minOrderCtrl.clear();
    _maxDiscountCtrl.clear();
    _quantityCtrl.text = '1';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    await ref
        .read(couponCreateControllerProvider.notifier)
        .uploadImage(businessId: widget.businessId, file: file);
  }

  bool _validateStep(int step) {
    final state = ref.read(couponCreateControllerProvider);
    switch (step) {
      case 0:
        return state.selectedType != null;
      case 1:
        return _step1FormKey.currentState?.validate() ?? false;
      case 2:
        return _validateRewardStep(state);
      case 3:
        return _step4FormKey.currentState?.validate() ?? false;
      default:
        return true;
    }
  }

  bool _validateRewardStep(CouponCreateState state) {
    final formValid = _step3FormKey.currentState?.validate() ?? false;
    if (!formValid) return false;

    if (state.selectedType == CouponType.freeProduct) {
      return state.selectedCategory != null && state.selectedProduct != null;
    }
    if (state.selectedType == CouponType.percentageDiscount) {
      return true;
    }
    if (state.selectedType == CouponType.fixedAmountDiscount) {
      return true;
    }
    return false;
  }

  void _nextStep() {
    final state = ref.read(couponCreateControllerProvider);
    if (!_validateStep(state.currentStep)) {
      _showValidationError(state.currentStep);
      return;
    }
    ref.read(couponCreateControllerProvider.notifier).nextStep();
  }

  void _showValidationError(int step) {
    String message = switch (step) {
      0 => 'Please select a coupon type.',
      1 => 'Please fill in all required fields.',
      2 => 'Please complete the reward configuration.',
      3 => 'Please set valid start and end dates.',
      _ => 'Please complete all required fields.',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final result = await ref
        .read(couponCreateControllerProvider.notifier)
        .submit(widget.businessId);
    if (!mounted) return;

    if (result != null) {
      // Refresh list and navigate back
      ref
          .read(couponListControllerProvider.notifier)
          .fetchCoupons(widget.businessId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon created successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/business/${widget.businessId}/coupons/${result.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponCreateState>(couponCreateControllerProvider, (prev, next) {
      if (next.submitError != null && next.submitError != prev?.submitError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.submitError!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final state = ref.watch(couponCreateControllerProvider);
    final businessProfileAsync = ref.watch(businessProfileControllerProvider);
    final businessProfileState =
        businessProfileAsync is AsyncData<BusinessProfilePageState>
        ? businessProfileAsync.value
        : null;
    final displayCurrency = CouponCurrency.fromBackend(
      businessProfileState?.business?.currencyCode ?? 'ALL',
    );
    final stepLabels = ['Type', 'Info', 'Reward', 'Schedule', 'Preview'];

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textOnDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Create Coupon',
          style: const TextStyle(color: AppColors.textOnDark),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _StepIndicator(
            currentStep: state.currentStep,
            stepLabels: stepLabels,
            onTap: (i) {
              if (i < state.currentStep) {
                ref.read(couponCreateControllerProvider.notifier).goToStep(i);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: IndexedStack(
                index: state.currentStep,
                children: [
                  _TypeStep(
                    selectedType: state.selectedType,
                    onSelect: (t) {
                      _resetFormForType();
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .selectType(t);
                    },
                  ),
                  _BasicInfoStep(
                    formKey: _step1FormKey,
                    titleCtrl: _titleCtrl,
                    descCtrl: _descCtrl,
                    termsCtrl: _termsCtrl,
                    pointsCtrl: _pointsCtrl,
                    state: state,
                    onPickImage: _pickImage,
                    onRemoveImage: () => ref
                        .read(couponCreateControllerProvider.notifier)
                        .removeImage(),
                    onFieldChanged: () {
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .updateBasicInfo(
                            title: _titleCtrl.text,
                            description: _descCtrl.text,
                            termsAndConditions: _termsCtrl.text,
                            pointsCost: _pointsCtrl.text,
                          );
                    },
                    onVisibilityChanged: (v) {
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .updateBasicInfo(visibility: v);
                    },
                    onPublishToggled: (v) {
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .updateBasicInfo(publishImmediately: v);
                    },
                  ),
                  _RewardStep(
                    formKey: _step3FormKey,
                    state: state,
                    businessId: widget.businessId,
                    currency: displayCurrency,
                    discountPctCtrl: _discountPctCtrl,
                    discountAmtCtrl: _discountAmtCtrl,
                    minOrderCtrl: _minOrderCtrl,
                    maxDiscountCtrl: _maxDiscountCtrl,
                    quantityCtrl: _quantityCtrl,
                    onDiscountChanged: () {
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .updateDiscountFields(
                            discountPercentage: _discountPctCtrl.text,
                            discountAmount: _discountAmtCtrl.text,
                            minimumOrderAmount: _minOrderCtrl.text,
                            maximumDiscountAmount: _maxDiscountCtrl.text,
                            quantity: _quantityCtrl.text,
                          );
                    },
                  ),
                  _AvailabilityStep(
                    formKey: _step4FormKey,
                    state: state,
                    totalLimitCtrl: _totalLimitCtrl,
                    perCustomerCtrl: _perCustomerLimitCtrl,
                    sortOrderCtrl: _sortOrderCtrl,
                    onChanged: () {
                      ref
                          .read(couponCreateControllerProvider.notifier)
                          .updateAvailability(
                            totalRedemptionLimit: _totalLimitCtrl.text,
                            perCustomerRedemptionLimit:
                                _perCustomerLimitCtrl.text,
                            sortOrder: _sortOrderCtrl.text,
                          );
                    },
                  ),
                  _PreviewStep(state: state, currency: displayCurrency),
                ],
              ),
            ),
            _BottomNavBar(
              currentStep: state.currentStep,
              totalSteps: stepLabels.length,
              isSubmitting: state.isSubmitting,
              isUploadingImage: state.isUploadingImage,
              onPrev: () =>
                  ref.read(couponCreateControllerProvider.notifier).prevStep(),
              onNext: _nextStep,
              onSubmit: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.currentStep,
    required this.stepLabels,
    required this.onTap,
  });

  final int currentStep;
  final List<String> stepLabels;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Row(
        children: List.generate(stepLabels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: stepIndex < currentStep
                    ? AppColors.primary
                    : AppColors.elevDark,
              ),
            );
          }
          final stepIndex = index ~/ 2;
          final isDone = stepIndex < currentStep;
          final isCurrent = stepIndex == currentStep;
          return GestureDetector(
            onTap: () => onTap(stepIndex),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? AppColors.primary
                        : isCurrent
                        ? AppColors.primaryDark
                        : AppColors.elevDark,
                    border: Border.all(
                      color: isCurrent ? AppColors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 12, color: Colors.white)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.primary
                                  : AppColors.textMutedDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stepLabels[stepIndex],
                  style: TextStyle(
                    color: isCurrent
                        ? AppColors.primary
                        : isDone
                        ? AppColors.textSubDark
                        : AppColors.textMutedDark,
                    fontSize: 9,
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentStep,
    required this.totalSteps,
    required this.isSubmitting,
    required this.isUploadingImage,
    required this.onPrev,
    required this.onNext,
    required this.onSubmit,
  });

  final int currentStep;
  final int totalSteps;
  final bool isSubmitting;
  final bool isUploadingImage;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;
    final isBusy = isSubmitting || isUploadingImage;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onPrev,
                icon: const Icon(Icons.arrow_back, size: 18),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSubDark,
                  side: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            )
          else
            const Expanded(child: SizedBox.shrink()),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isBusy ? null : (isLast ? onSubmit : onNext),
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(isLast ? Icons.check : Icons.arrow_forward, size: 18),
              label: Text(
                isBusy
                    ? (isSubmitting ? 'Creating...' : 'Uploading...')
                    : (isLast ? 'Create Coupon' : 'Next'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 0: Type Selector ─────────────────────────────────────────────────────

class _TypeStep extends StatelessWidget {
  const _TypeStep({required this.selectedType, required this.onSelect});

  final CouponType? selectedType;
  final void Function(CouponType) onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Coupon Type',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose how you want to reward your customers.',
            style: TextStyle(color: AppColors.textSubDark, fontSize: 14),
          ),
          const SizedBox(height: 24),
          for (final type in CouponType.values)
            _TypeCard(
              type: type,
              isSelected: selectedType == type,
              onTap: () => onSelect(type),
            ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  final CouponType type;
  final bool isSelected;
  final VoidCallback onTap;

  String get _description => switch (type) {
    CouponType.freeProduct =>
      'Give customers a free product when they redeem loyalty points.',
    CouponType.percentageDiscount =>
      'Offer a percentage off the total order amount.',
    CouponType.fixedAmountDiscount =>
      'Discount a fixed amount from the order total.',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? type.color.withValues(alpha: 0.12)
              : AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? type.color.withValues(alpha: 0.6)
                : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(type.icon, color: type.color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.displayName,
                    style: TextStyle(
                      color: isSelected ? type.color : AppColors.textOnDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _description,
                    style: const TextStyle(
                      color: AppColors.textSubDark,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected ? type.color : AppColors.textMutedDark,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step 1: Basic Info ────────────────────────────────────────────────────────

class _BasicInfoStep extends StatelessWidget {
  const _BasicInfoStep({
    required this.formKey,
    required this.titleCtrl,
    required this.descCtrl,
    required this.termsCtrl,
    required this.pointsCtrl,
    required this.state,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onFieldChanged,
    required this.onVisibilityChanged,
    required this.onPublishToggled,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController termsCtrl;
  final TextEditingController pointsCtrl;
  final CouponCreateState state;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onFieldChanged;
  final void Function(CouponVisibility) onVisibilityChanged;
  final void Function(bool) onPublishToggled;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coupon Details',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            TextFormField(
              controller: titleCtrl,
              onChanged: (_) => onFieldChanged(),
              style: const TextStyle(color: AppColors.textOnDark),
              maxLength: 200,
              decoration: _fieldDecoration(
                'Coupon Title *',
                'e.g., Free Cappuccino',
              ),
              validator: (v) =>
                  v?.trim().isEmpty ?? true ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: descCtrl,
              onChanged: (_) => onFieldChanged(),
              style: const TextStyle(color: AppColors.textOnDark),
              maxLength: 1000,
              maxLines: 3,
              decoration: _fieldDecoration(
                'Description (Optional)',
                'Leave empty to auto-generate.',
              ),
            ),
            const SizedBox(height: 16),

            // Points cost
            TextFormField(
              controller: pointsCtrl,
              onChanged: (_) => onFieldChanged(),
              style: const TextStyle(color: AppColors.gold),
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration('Loyalty Points Cost *', '250')
                  .copyWith(
                    prefixIcon: const Icon(
                      Icons.monetization_on,
                      color: AppColors.gold,
                      size: 20,
                    ),
                  ),
              validator: (v) {
                final n = int.tryParse(v?.trim() ?? '');
                if (n == null || n < 1) return 'Must be at least 1 point';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Coupon photo
            const Text(
              'Promotional Photo (Optional)',
              style: TextStyle(color: AppColors.textSubDark, fontSize: 13),
            ),
            const SizedBox(height: 8),
            _ImagePicker(
              state: state,
              onPick: onPickImage,
              onRemove: onRemoveImage,
            ),
            const SizedBox(height: 16),

            // Visibility
            const Text(
              'Visibility',
              style: TextStyle(color: AppColors.textSubDark, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: CouponVisibility.values.map((v) {
                final isSelected = state.visibility == v;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onVisibilityChanged(v),
                    child: Container(
                      margin: EdgeInsets.only(
                        right: v == CouponVisibility.public ? 8 : 0,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? v.color.withValues(alpha: 0.12)
                            : AppColors.elevDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? v.color.withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            v.icon,
                            size: 16,
                            color: isSelected
                                ? v.color
                                : AppColors.textMutedDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v.displayName,
                            style: TextStyle(
                              color: isSelected
                                  ? v.color
                                  : AppColors.textSubDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Terms
            TextFormField(
              controller: termsCtrl,
              onChanged: (_) => onFieldChanged(),
              style: const TextStyle(color: AppColors.textOnDark),
              maxLength: 2000,
              maxLines: 4,
              decoration: _fieldDecoration(
                'Terms & Conditions (Optional)',
                'e.g., Valid once per customer.',
              ),
            ),
            const SizedBox(height: 8),

            // Publish toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.elevDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Publish Immediately',
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          state.publishImmediately
                              ? 'Coupon will be set to Active'
                              : 'Coupon will be saved as Draft',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.publishImmediately,
                    onChanged: onPublishToggled,
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSubDark),
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
        filled: true,
        fillColor: AppColors.elevDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      );
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.state,
    required this.onPick,
    required this.onRemove,
  });

  final CouponCreateState state;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (state.isUploadingImage) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.elevDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              'Uploading...',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (state.uploadedImageUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              state.uploadedImageUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.elevDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: state.imageError != null
                ? AppColors.error
                : AppColors.glassBorder,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.textMutedDark,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap to upload photo',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
            ),
            if (state.imageError != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  state.imageError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Step 2: Reward Config ─────────────────────────────────────────────────────

class _RewardStep extends ConsumerWidget {
  const _RewardStep({
    required this.formKey,
    required this.state,
    required this.businessId,
    required this.currency,
    required this.discountPctCtrl,
    required this.discountAmtCtrl,
    required this.minOrderCtrl,
    required this.maxDiscountCtrl,
    required this.quantityCtrl,
    required this.onDiscountChanged,
  });

  final GlobalKey<FormState> formKey;
  final CouponCreateState state;
  final int businessId;
  final CouponCurrency currency;
  final TextEditingController discountPctCtrl;
  final TextEditingController discountAmtCtrl;
  final TextEditingController minOrderCtrl;
  final TextEditingController maxDiscountCtrl;
  final TextEditingController quantityCtrl;
  final VoidCallback onDiscountChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctrl = ref.read(couponCreateControllerProvider.notifier);

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CouponTypeBadge(type: state.selectedType!),
                const SizedBox(width: 10),
                const Text(
                  'Reward Configuration',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (state.selectedType == CouponType.freeProduct)
              _FreeProductSection(
                state: state,
                businessId: businessId,
                quantityCtrl: quantityCtrl,
                onQuantityChanged: onDiscountChanged,
                onLoadCategories: () => ctrl.loadCategories(businessId),
                onSelectCategory: (cat) =>
                    ctrl.selectCategory(businessId: businessId, category: cat),
                onSelectProduct: (prod) =>
                    ctrl.selectProduct(businessId: businessId, product: prod),
                onSelectVariant: ctrl.selectVariant,
              )
            else if (state.selectedType == CouponType.percentageDiscount)
              _PercentageDiscountSection(
                currency: currency,
                discountPctCtrl: discountPctCtrl,
                minOrderCtrl: minOrderCtrl,
                maxDiscountCtrl: maxDiscountCtrl,
                onChanged: onDiscountChanged,
              )
            else if (state.selectedType == CouponType.fixedAmountDiscount)
              _FixedAmountSection(
                currency: currency,
                discountAmtCtrl: discountAmtCtrl,
                minOrderCtrl: minOrderCtrl,
                onChanged: onDiscountChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _FreeProductSection extends ConsumerStatefulWidget {
  const _FreeProductSection({
    required this.state,
    required this.businessId,
    required this.quantityCtrl,
    required this.onQuantityChanged,
    required this.onLoadCategories,
    required this.onSelectCategory,
    required this.onSelectProduct,
    required this.onSelectVariant,
  });

  final CouponCreateState state;
  final int businessId;
  final TextEditingController quantityCtrl;
  final VoidCallback onQuantityChanged;
  final VoidCallback onLoadCategories;
  final void Function(CategoryLookup) onSelectCategory;
  final void Function(ProductLookup) onSelectProduct;
  final void Function(VariantLookup?) onSelectVariant;

  @override
  ConsumerState<_FreeProductSection> createState() =>
      _FreeProductSectionState();
}

class _FreeProductSectionState extends ConsumerState<_FreeProductSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(couponCreateControllerProvider);
      if (state.categories.isEmpty) {
        widget.onLoadCategories();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (state.lookupError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.lookupError!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Category
        _DropdownField<CategoryLookup>(
          label: 'Category *',
          hint: state.isLoadingCategories
              ? 'Loading categories...'
              : 'Select a category',
          value: state.selectedCategory,
          items: state.categories,
          isLoading: state.isLoadingCategories,
          isEnabled: !state.isLoadingCategories,
          itemLabel: (c) => c.name,
          onChanged: (value) {
            if (value != null) widget.onSelectCategory(value);
          },
          emptyMessage: 'No active categories available',
        ),
        const SizedBox(height: 14),

        // Product
        _DropdownField<ProductLookup>(
          label: 'Product *',
          hint: state.selectedCategory == null
              ? 'Select a category first'
              : state.isLoadingProducts
              ? 'Loading products...'
              : 'Select a product',
          value: state.selectedProduct,
          items: state.products,
          isLoading: state.isLoadingProducts,
          isEnabled: state.selectedCategory != null && !state.isLoadingProducts,
          itemLabel: (p) => p.name,
          onChanged: (value) {
            if (value != null) widget.onSelectProduct(value);
          },
          emptyMessage: 'No active products in this category',
        ),
        const SizedBox(height: 14),

        // Variant
        _DropdownField<VariantLookup>(
          label: 'Variant (Optional)',
          hint: state.selectedProduct == null
              ? 'Select a product first'
              : state.isLoadingVariants
              ? 'Loading variants...'
              : state.variants.isEmpty
              ? 'No variants available'
              : 'Select a variant (optional)',
          value: state.selectedVariant,
          items: state.variants,
          isLoading: state.isLoadingVariants,
          isEnabled: state.selectedProduct != null && !state.isLoadingVariants,
          itemLabel: (v) =>
              v.name + (v.priceLabel.isNotEmpty ? ' — ${v.priceLabel}' : ''),
          onChanged: widget.onSelectVariant,
          emptyMessage: 'No variants available for this product',
          isRequired: false,
          allowNone: true,
          noneLabel: 'No variant',
        ),
        const SizedBox(height: 14),

        // Quantity
        TextFormField(
          controller: widget.quantityCtrl,
          onChanged: (_) => widget.onQuantityChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: TextInputType.number,
          decoration: _fieldDecoration('Quantity', '1'),
          validator: (v) {
            final n = int.tryParse(v?.trim() ?? '');
            if (n == null || n < 1) return 'Must be at least 1';
            return null;
          },
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.isLoading,
    required this.isEnabled,
    required this.itemLabel,
    required this.onChanged,
    required this.emptyMessage,
    this.isRequired = true,
    this.allowNone = false,
    this.noneLabel,
  });

  final String label;
  final String hint;
  final T? value;
  final List<T> items;
  final bool isLoading;
  final bool isEnabled;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;
  final String emptyMessage;
  final bool isRequired;
  final bool allowNone;
  final String? noneLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSubDark, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.elevDark : AppColors.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : !isEnabled && items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 13,
                    ),
                  ),
                )
              : isEnabled && items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : DropdownButtonFormField<T>(
                  initialValue: value,
                  hint: Text(
                    hint,
                    style: const TextStyle(
                      color: AppColors.textMutedDark,
                      fontSize: 13,
                    ),
                  ),
                  dropdownColor: AppColors.elevDark,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  isExpanded: true,
                  items: [
                    if (allowNone)
                      DropdownMenuItem<T>(
                        value: null,
                        child: Text(
                          noneLabel ?? 'None',
                          style: const TextStyle(
                            color: AppColors.textMutedDark,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ...items.map(
                      (item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(
                          itemLabel(item),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: isEnabled ? onChanged : null,
                  validator: isRequired
                      ? (v) => v == null
                            ? '${label.replaceAll(' *', '')} is required'
                            : null
                      : null,
                ),
        ),
      ],
    );
  }
}

class _PercentageDiscountSection extends StatelessWidget {
  const _PercentageDiscountSection({
    required this.currency,
    required this.discountPctCtrl,
    required this.minOrderCtrl,
    required this.maxDiscountCtrl,
    required this.onChanged,
  });

  final CouponCurrency currency;
  final TextEditingController discountPctCtrl;
  final TextEditingController minOrderCtrl;
  final TextEditingController maxDiscountCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: discountPctCtrl,
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            'Discount Percentage *',
            'e.g., 10',
          ).copyWith(suffixText: '%'),
          validator: (v) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0 || n > 100) {
              return 'Must be between 0 and 100';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: minOrderCtrl,
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            'Minimum Order Amount (${currency.displayCode}) (Optional)',
            'e.g., 20.00',
          ),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return null;
            final n = double.tryParse(v!.trim());
            if (n == null || n < 0) return 'Must be 0 or more';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: maxDiscountCtrl,
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            'Maximum Discount Amount (${currency.displayCode}) (Optional)',
            'e.g., 10.00',
          ),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return null;
            final n = double.tryParse(v!.trim());
            if (n == null || n < 0) return 'Must be 0 or more';
            return null;
          },
        ),
      ],
    );
  }
}

class _FixedAmountSection extends StatelessWidget {
  const _FixedAmountSection({
    required this.currency,
    required this.discountAmtCtrl,
    required this.minOrderCtrl,
    required this.onChanged,
  });

  final CouponCurrency currency;
  final TextEditingController discountAmtCtrl;
  final TextEditingController minOrderCtrl;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: discountAmtCtrl,
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            'Discount Amount (${currency.displayCode}) *',
            'e.g., 5.00',
          ),
          validator: (v) {
            final n = double.tryParse(v?.trim() ?? '');
            if (n == null || n <= 0) return 'Must be greater than 0';
            return null;
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: minOrderCtrl,
          onChanged: (_) => onChanged(),
          style: const TextStyle(color: AppColors.textOnDark),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: _fieldDecoration(
            'Minimum Order Amount (${currency.displayCode}) (Optional)',
            'e.g., 30.00',
          ),
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return null;
            final n = double.tryParse(v!.trim());
            if (n == null || n < 0) return 'Must be 0 or more';
            return null;
          },
        ),
      ],
    );
  }
}

InputDecoration _fieldDecoration(String label, String hint) => InputDecoration(
  labelText: label,
  hintText: hint,
  labelStyle: const TextStyle(color: AppColors.textSubDark),
  hintStyle: const TextStyle(color: AppColors.textMutedDark),
  filled: true,
  fillColor: AppColors.elevDark,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.glassBorder),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.glassBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.primary),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: AppColors.error),
  ),
);

// ── Step 3: Availability ──────────────────────────────────────────────────────

class _AvailabilityStep extends ConsumerWidget {
  const _AvailabilityStep({
    required this.formKey,
    required this.state,
    required this.totalLimitCtrl,
    required this.perCustomerCtrl,
    required this.sortOrderCtrl,
    required this.onChanged,
  });

  final GlobalKey<FormState> formKey;
  final CouponCreateState state;
  final TextEditingController totalLimitCtrl;
  final TextEditingController perCustomerCtrl;
  final TextEditingController sortOrderCtrl;
  final VoidCallback onChanged;

  Future<void> _pickDate(
    BuildContext context,
    WidgetRef ref, {
    required bool isStart,
  }) async {
    final now = DateTime.now();
    final initial = isStart
        ? (state.startDate ?? now)
        : (state.endDate ?? now.add(const Duration(days: 30)));
    final first = isStart ? now : (state.startDate ?? now);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final dt = isStart
        ? DateTime(picked.year, picked.month, picked.day, 0, 0, 0)
        : DateTime(picked.year, picked.month, picked.day, 23, 59, 59);

    ref
        .read(couponCreateControllerProvider.notifier)
        .updateAvailability(
          startDate: isStart ? dt : state.startDate,
          endDate: isStart ? state.endDate : dt,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Availability & Limits',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Date range
            Row(
              children: [
                Expanded(
                  child: _DateField(
                    label: 'Start Date *',
                    date: state.startDate,
                    onTap: () => _pickDate(context, ref, isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateField(
                    label: 'End Date *',
                    date: state.endDate,
                    onTap: () => _pickDate(context, ref, isStart: false),
                    isError:
                        state.endDate != null &&
                        state.startDate != null &&
                        state.endDate!.isBefore(state.startDate!),
                    errorText: 'Must be after start',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Redemption limits
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: totalLimitCtrl,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(color: AppColors.textOnDark),
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                      'Total Limit (Optional)',
                      'e.g., 500',
                    ),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return null;
                      final n = int.tryParse(v!.trim());
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: perCustomerCtrl,
                    onChanged: (_) => onChanged(),
                    style: const TextStyle(color: AppColors.textOnDark),
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                      'Per Customer (Optional)',
                      'e.g., 1',
                    ),
                    validator: (v) {
                      if (v?.trim().isEmpty ?? true) return null;
                      final n = int.tryParse(v!.trim());
                      if (n == null || n < 1) return 'Min 1';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sort order
            TextFormField(
              controller: sortOrderCtrl,
              onChanged: (_) => onChanged(),
              style: const TextStyle(color: AppColors.textOnDark),
              keyboardType: TextInputType.number,
              decoration: _fieldDecoration('Sort Order (Optional)', 'e.g., 1'),
            ),
            const SizedBox(height: 16),

            // Featured toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.elevDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_outline,
                    color: AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Featured Coupon',
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Show this coupon prominently to customers.',
                          style: TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: state.isFeatured,
                    onChanged: (v) => ref
                        .read(couponCreateControllerProvider.notifier)
                        .updateAvailability(isFeatured: v),
                    activeThumbColor: AppColors.gold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
    this.isError = false,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final bool isError;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final dateStr = date != null
        ? '${date!.day}/${date!.month}/${date!.year}'
        : 'Not set';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.elevDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isError
                ? AppColors.error
                : date != null
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: date != null
                        ? AppColors.textOnDark
                        : AppColors.textMutedDark,
                    fontSize: 13,
                    fontWeight: date != null
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (isError && errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  errorText!,
                  style: const TextStyle(color: AppColors.error, fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Step 4: Preview ───────────────────────────────────────────────────────────

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({required this.state, required this.currency});

  final CouponCreateState state;
  final CouponCurrency currency;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Preview & Confirm',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Review your coupon before creating it.',
            style: TextStyle(color: AppColors.textSubDark, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (state.selectedType != null)
            CouponPreviewCard(
              type: state.selectedType!,
              title: state.title,
              description: state.description,
              imageUrl: state.uploadedImageUrl,
              pointsCost: state.pointsCost,
              visibility: state.visibility,
              publishImmediately: state.publishImmediately,
              startDate: state.startDate,
              endDate: state.endDate,
              selectedCategory: state.selectedCategory,
              selectedProduct: state.selectedProduct,
              selectedVariant: state.selectedVariant,
              quantity: state.quantity,
              discountPercentage: state.discountPercentage.isEmpty
                  ? null
                  : state.discountPercentage,
              discountAmount: state.discountAmount.isEmpty
                  ? null
                  : state.discountAmount,
              minimumOrderAmount: state.minimumOrderAmount.isEmpty
                  ? null
                  : state.minimumOrderAmount,
              maximumDiscountAmount: state.maximumDiscountAmount.isEmpty
                  ? null
                  : state.maximumDiscountAmount,
              currency: currency,
            ),
          if (state.submitError != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.submitError!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
