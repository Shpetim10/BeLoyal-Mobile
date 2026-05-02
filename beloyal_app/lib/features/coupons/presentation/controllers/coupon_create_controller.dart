import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/coupon_repository.dart';
import '../../data/models/coupon_create_request.dart';
import '../../data/models/coupon_detail.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_lookup_models.dart';

class CouponCreateState {
  const CouponCreateState({
    this.currentStep = 0,
    // Step 1 type
    this.selectedType,
    // Step 2 basic info
    this.title = '',
    this.description = '',
    this.termsAndConditions = '',
    this.pointsCost = '',
    this.visibility = CouponVisibility.public,
    this.publishImmediately = false,
    // Image
    this.selectedImage,
    this.uploadedImageUrl,
    this.isUploadingImage = false,
    this.imageError,
    // Step 3 free product
    this.categories = const [],
    this.products = const [],
    this.variants = const [],
    this.isLoadingCategories = false,
    this.isLoadingProducts = false,
    this.isLoadingVariants = false,
    this.selectedCategory,
    this.selectedProduct,
    this.selectedVariant,
    this.quantity = '1',
    this.lookupError,
    // Step 3 discount
    this.discountPercentage = '',
    this.discountAmount = '',
    this.minimumOrderAmount = '',
    this.maximumDiscountAmount = '',
    // Step 4 availability
    this.startDate,
    this.endDate,
    this.totalRedemptionLimit = '',
    this.perCustomerRedemptionLimit = '',
    this.isFeatured = false,
    this.sortOrder = '',
    // Submit
    this.isSubmitting = false,
    this.submitError,
    this.createdCoupon,
  });

  final int currentStep;
  final CouponType? selectedType;

  final String title;
  final String description;
  final String termsAndConditions;
  final String pointsCost;
  final CouponVisibility visibility;
  final bool publishImmediately;

  final XFile? selectedImage;
  final String? uploadedImageUrl;
  final bool isUploadingImage;
  final String? imageError;

  final List<CategoryLookup> categories;
  final List<ProductLookup> products;
  final List<VariantLookup> variants;
  final bool isLoadingCategories;
  final bool isLoadingProducts;
  final bool isLoadingVariants;
  final CategoryLookup? selectedCategory;
  final ProductLookup? selectedProduct;
  final VariantLookup? selectedVariant;
  final String quantity;
  final String? lookupError;

  final String discountPercentage;
  final String discountAmount;
  final String minimumOrderAmount;
  final String maximumDiscountAmount;

  final DateTime? startDate;
  final DateTime? endDate;
  final String totalRedemptionLimit;
  final String perCustomerRedemptionLimit;
  final bool isFeatured;
  final String sortOrder;

  final bool isSubmitting;
  final String? submitError;
  final CouponDetail? createdCoupon;

  CouponCreateState copyWith({
    int? currentStep,
    CouponType? selectedType,
    String? title,
    String? description,
    String? termsAndConditions,
    String? pointsCost,
    CouponVisibility? visibility,
    bool? publishImmediately,
    XFile? selectedImage,
    bool clearSelectedImage = false,
    String? uploadedImageUrl,
    bool clearUploadedImageUrl = false,
    bool? isUploadingImage,
    String? imageError,
    bool clearImageError = false,
    List<CategoryLookup>? categories,
    List<ProductLookup>? products,
    List<VariantLookup>? variants,
    bool? isLoadingCategories,
    bool? isLoadingProducts,
    bool? isLoadingVariants,
    CategoryLookup? selectedCategory,
    bool clearSelectedCategory = false,
    ProductLookup? selectedProduct,
    bool clearSelectedProduct = false,
    VariantLookup? selectedVariant,
    bool clearSelectedVariant = false,
    String? quantity,
    String? lookupError,
    bool clearLookupError = false,
    String? discountPercentage,
    String? discountAmount,
    String? minimumOrderAmount,
    String? maximumDiscountAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? totalRedemptionLimit,
    String? perCustomerRedemptionLimit,
    bool? isFeatured,
    String? sortOrder,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    CouponDetail? createdCoupon,
  }) {
    return CouponCreateState(
      currentStep: currentStep ?? this.currentStep,
      selectedType: selectedType ?? this.selectedType,
      title: title ?? this.title,
      description: description ?? this.description,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      pointsCost: pointsCost ?? this.pointsCost,
      visibility: visibility ?? this.visibility,
      publishImmediately: publishImmediately ?? this.publishImmediately,
      selectedImage: clearSelectedImage
          ? null
          : (selectedImage ?? this.selectedImage),
      uploadedImageUrl: clearUploadedImageUrl
          ? null
          : (uploadedImageUrl ?? this.uploadedImageUrl),
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
      imageError: clearImageError ? null : (imageError ?? this.imageError),
      categories: categories ?? this.categories,
      products: products ?? this.products,
      variants: variants ?? this.variants,
      isLoadingCategories: isLoadingCategories ?? this.isLoadingCategories,
      isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
      isLoadingVariants: isLoadingVariants ?? this.isLoadingVariants,
      selectedCategory: clearSelectedCategory
          ? null
          : (selectedCategory ?? this.selectedCategory),
      selectedProduct: clearSelectedProduct
          ? null
          : (selectedProduct ?? this.selectedProduct),
      selectedVariant: clearSelectedVariant
          ? null
          : (selectedVariant ?? this.selectedVariant),
      quantity: quantity ?? this.quantity,
      lookupError: clearLookupError ? null : (lookupError ?? this.lookupError),
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      maximumDiscountAmount:
          maximumDiscountAmount ?? this.maximumDiscountAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalRedemptionLimit: totalRedemptionLimit ?? this.totalRedemptionLimit,
      perCustomerRedemptionLimit:
          perCustomerRedemptionLimit ?? this.perCustomerRedemptionLimit,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      createdCoupon: createdCoupon ?? this.createdCoupon,
    );
  }
}

class CouponCreateController extends Notifier<CouponCreateState> {
  @override
  CouponCreateState build() => const CouponCreateState();

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  void reset() {
    state = const CouponCreateState();
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void prevStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void selectType(CouponType type) {
    state = state.copyWith(selectedType: type, currentStep: 1);
  }

  void updateBasicInfo({
    String? title,
    String? description,
    String? termsAndConditions,
    String? pointsCost,
    CouponVisibility? visibility,
    bool? publishImmediately,
  }) {
    state = state.copyWith(
      title: title,
      description: description,
      termsAndConditions: termsAndConditions,
      pointsCost: pointsCost,
      visibility: visibility,
      publishImmediately: publishImmediately,
    );
  }

  Future<void> uploadImage({
    required int businessId,
    required XFile file,
  }) async {
    state = state.copyWith(
      selectedImage: file,
      isUploadingImage: true,
      clearImageError: true,
      clearUploadedImageUrl: true,
    );
    try {
      final result = await _repo.uploadCouponImage(
        businessId: businessId,
        file: file,
      );
      state = state.copyWith(
        uploadedImageUrl: result.url,
        isUploadingImage: false,
      );
    } catch (e) {
      state = state.copyWith(
        isUploadingImage: false,
        imageError: _extractMessage(e),
        clearSelectedImage: true,
      );
    }
  }

  void removeImage() {
    state = state.copyWith(
      clearSelectedImage: true,
      clearUploadedImageUrl: true,
      clearImageError: true,
    );
  }

  Future<void> loadCategories(int businessId) async {
    state = state.copyWith(
      isLoadingCategories: true,
      clearLookupError: true,
      categories: [],
    );
    try {
      final cats = await _repo.lookupCategories(businessId: businessId);
      state = state.copyWith(categories: cats, isLoadingCategories: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingCategories: false,
        lookupError: _extractMessage(e),
      );
    }
  }

  Future<void> selectCategory({
    required int businessId,
    required CategoryLookup category,
  }) async {
    state = state.copyWith(
      selectedCategory: category,
      clearSelectedProduct: true,
      clearSelectedVariant: true,
      products: [],
      variants: [],
      isLoadingProducts: true,
      clearLookupError: true,
    );
    try {
      final prods = await _repo.lookupProducts(
        businessId: businessId,
        categoryId: category.id,
      );
      state = state.copyWith(products: prods, isLoadingProducts: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingProducts: false,
        lookupError: _extractMessage(e),
      );
    }
  }

  Future<void> selectProduct({
    required int businessId,
    required ProductLookup product,
  }) async {
    state = state.copyWith(
      selectedProduct: product,
      clearSelectedVariant: true,
      variants: [],
      isLoadingVariants: true,
      clearLookupError: true,
    );
    try {
      final vars = await _repo.lookupVariants(
        businessId: businessId,
        productId: product.id,
      );
      state = state.copyWith(variants: vars, isLoadingVariants: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingVariants: false,
        lookupError: _extractMessage(e),
      );
    }
  }

  void selectVariant(VariantLookup? variant) {
    if (variant == null) {
      state = state.copyWith(clearSelectedVariant: true);
    } else {
      state = state.copyWith(selectedVariant: variant);
    }
  }

  void updateDiscountFields({
    String? discountPercentage,
    String? discountAmount,
    String? minimumOrderAmount,
    String? maximumDiscountAmount,
    String? quantity,
  }) {
    state = state.copyWith(
      discountPercentage: discountPercentage,
      discountAmount: discountAmount,
      minimumOrderAmount: minimumOrderAmount,
      maximumDiscountAmount: maximumDiscountAmount,
      quantity: quantity,
    );
  }

  void updateAvailability({
    DateTime? startDate,
    DateTime? endDate,
    String? totalRedemptionLimit,
    String? perCustomerRedemptionLimit,
    bool? isFeatured,
    String? sortOrder,
  }) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      totalRedemptionLimit: totalRedemptionLimit,
      perCustomerRedemptionLimit: perCustomerRedemptionLimit,
      isFeatured: isFeatured,
      sortOrder: sortOrder,
    );
  }

  Future<CouponDetail?> submit(int businessId) async {
    final s = state;
    if (s.selectedType == null) return null;

    state = state.copyWith(isSubmitting: true, clearSubmitError: true);

    try {
      final request = CouponCreateRequest(
        type: s.selectedType!,
        title: s.title.trim(),
        description: s.description.trim().isEmpty ? null : s.description.trim(),
        imageUrl: s.uploadedImageUrl,
        pointsCost: int.parse(s.pointsCost),
        startDate: s.startDate!,
        endDate: s.endDate!,
        status: s.publishImmediately ? CouponStatus.active : CouponStatus.draft,
        visibility: s.visibility,
        termsAndConditions: s.termsAndConditions.trim().isEmpty
            ? null
            : s.termsAndConditions.trim(),
        isFeatured: s.isFeatured,
        sortOrder: s.sortOrder.trim().isEmpty
            ? null
            : int.tryParse(s.sortOrder.trim()),
        totalRedemptionLimit: s.totalRedemptionLimit.trim().isEmpty
            ? null
            : int.tryParse(s.totalRedemptionLimit.trim()),
        perCustomerRedemptionLimit: s.perCustomerRedemptionLimit.trim().isEmpty
            ? null
            : int.tryParse(s.perCustomerRedemptionLimit.trim()),
        categoryId: s.selectedCategory?.id,
        productId: s.selectedProduct?.id,
        variantId: s.selectedVariant?.id,
        quantity: s.selectedType == CouponType.freeProduct
            ? int.tryParse(s.quantity) ?? 1
            : null,
        discountPercentage: s.discountPercentage.trim().isEmpty
            ? null
            : double.tryParse(s.discountPercentage.trim()),
        discountAmount: s.discountAmount.trim().isEmpty
            ? null
            : double.tryParse(s.discountAmount.trim()),
        minimumOrderAmount: s.minimumOrderAmount.trim().isEmpty
            ? null
            : double.tryParse(s.minimumOrderAmount.trim()),
        maximumDiscountAmount:
            s.selectedType == CouponType.percentageDiscount &&
                s.maximumDiscountAmount.trim().isNotEmpty
            ? double.tryParse(s.maximumDiscountAmount.trim())
            : null,
      );

      final created = await _repo.createCoupon(
        businessId: businessId,
        request: request,
      );
      state = state.copyWith(isSubmitting: false, createdCoupon: created);
      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: _extractMessage(e),
      );
      return null;
    }
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final code = (data['code'] ?? data['errorCode'])?.toString();
        final mapped = _mapBackendErrorCode(code);
        if (mapped != null) return mapped;
        return (data['message'] as String?) ?? 'Something went wrong';
      }
      return 'Network error. Check your connection.';
    }
    return error.toString();
  }

  String? _mapBackendErrorCode(String? code) => switch (code) {
    'CATEGORY_NOT_ACTIVE' =>
      'The selected category is no longer active. Please select another category.',
    'PRODUCT_NOT_ACTIVE' =>
      'The selected product is no longer active. Please select another product.',
    'VARIANT_NOT_ACTIVE' =>
      'The selected variant is no longer active. Please select another variant.',
    'INVALID_POINTS_COST' => 'Points cost must be greater than 0.',
    'INVALID_DATE_RANGE' => 'End date must be after start date.',
    _ => null,
  };
}

final couponCreateControllerProvider =
    NotifierProvider<CouponCreateController, CouponCreateState>(
      CouponCreateController.new,
    );
