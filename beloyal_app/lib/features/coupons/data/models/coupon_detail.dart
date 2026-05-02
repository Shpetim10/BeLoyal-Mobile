import 'coupon_enums.dart';

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is List && v.length >= 3) {
    return DateTime(
      (v[0] as num).toInt(),
      (v[1] as num).toInt(),
      (v[2] as num).toInt(),
      v.length > 3 ? (v[3] as num).toInt() : 0,
      v.length > 4 ? (v[4] as num).toInt() : 0,
    );
  }
  return null;
}

class FreeProductDetails {
  const FreeProductDetails({
    required this.categoryId,
    required this.categoryName,
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantName,
    required this.quantity,
  });

  final int categoryId;
  final String categoryName;
  final int productId;
  final String productName;
  final int? variantId;
  final String? variantName;
  final int quantity;

  factory FreeProductDetails.fromJson(Map<String, dynamic> json) =>
      FreeProductDetails(
        categoryId: (json['categoryId'] as num).toInt(),
        categoryName: json['categoryName']?.toString() ?? '',
        productId: (json['productId'] as num).toInt(),
        productName: json['productName']?.toString() ?? '',
        variantId: (json['variantId'] as num?)?.toInt(),
        variantName: json['variantName']?.toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

class DiscountDetails {
  const DiscountDetails({
    this.discountPercentage,
    this.discountAmount,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
  });

  final double? discountPercentage;
  final double? discountAmount;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;

  factory DiscountDetails.fromJson(Map<String, dynamic> json) =>
      DiscountDetails(
        discountPercentage: json['discountPercentage'] != null
            ? (json['discountPercentage'] as num).toDouble()
            : null,
        discountAmount: json['discountAmount'] != null
            ? (json['discountAmount'] as num).toDouble()
            : null,
        minimumOrderAmount: json['minimumOrderAmount'] != null
            ? (json['minimumOrderAmount'] as num).toDouble()
            : null,
        maximumDiscountAmount: json['maximumDiscountAmount'] != null
            ? (json['maximumDiscountAmount'] as num).toDouble()
            : null,
      );
}

class CouponDetail {
  const CouponDetail({
    required this.id,
    required this.businessId,
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    required this.pointsCost,
    required this.currency,
    required this.status,
    required this.visibility,
    required this.startDate,
    required this.endDate,
    this.totalRedemptionLimit,
    required this.totalRedemptions,
    this.perCustomerRedemptionLimit,
    this.termsAndConditions,
    required this.isFeatured,
    this.sortOrder,
    required this.createdAt,
    this.updatedAt,
    this.freeProductDetails,
    this.discountDetails,
  });

  final int id;
  final int businessId;
  final CouponType type;
  final String title;
  final String? description;
  final String? imageUrl;
  final int pointsCost;
  final CouponCurrency currency;
  final CouponStatus status;
  final CouponVisibility visibility;
  final DateTime startDate;
  final DateTime endDate;
  final int? totalRedemptionLimit;
  final int totalRedemptions;
  final int? perCustomerRedemptionLimit;
  final String? termsAndConditions;
  final bool isFeatured;
  final int? sortOrder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final FreeProductDetails? freeProductDetails;
  final DiscountDetails? discountDetails;

  factory CouponDetail.fromJson(Map<String, dynamic> json) {
    return CouponDetail(
      id: (json['id'] as num).toInt(),
      businessId: (json['businessId'] as num?)?.toInt() ?? 0,
      type: CouponType.fromBackend(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      currency: CouponCurrency.fromBackend(json['currency']?.toString() ?? 'LEK'),
      status: CouponStatus.fromBackend(json['status']?.toString() ?? 'DRAFT'),
      visibility: CouponVisibility.fromBackend(json['visibility']?.toString() ?? 'PUBLIC'),
      startDate: _parseDate(json['startDate']) ?? DateTime.now(),
      endDate: _parseDate(json['endDate']) ?? DateTime.now(),
      totalRedemptionLimit: (json['totalRedemptionLimit'] as num?)?.toInt(),
      totalRedemptions: (json['totalRedemptions'] as num?)?.toInt() ?? 0,
      perCustomerRedemptionLimit: (json['perCustomerRedemptionLimit'] as num?)?.toInt(),
      termsAndConditions: json['termsAndConditions']?.toString(),
      isFeatured: json['isFeatured'] as bool? ?? false,
      sortOrder: (json['sortOrder'] as num?)?.toInt(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      freeProductDetails: json['freeProductDetails'] != null
          ? FreeProductDetails.fromJson(
              json['freeProductDetails'] as Map<String, dynamic>)
          : null,
      discountDetails: json['discountDetails'] != null
          ? DiscountDetails.fromJson(
              json['discountDetails'] as Map<String, dynamic>)
          : null,
    );
  }
}
