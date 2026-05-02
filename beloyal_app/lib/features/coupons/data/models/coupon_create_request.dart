import 'coupon_enums.dart';

class CouponCreateRequest {
  const CouponCreateRequest({
    required this.type,
    required this.title,
    this.description,
    this.imageUrl,
    required this.pointsCost,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.visibility,
    this.termsAndConditions,
    this.isFeatured,
    this.sortOrder,
    this.totalRedemptionLimit,
    this.perCustomerRedemptionLimit,
    // FREE_PRODUCT
    this.categoryId,
    this.productId,
    this.variantId,
    this.quantity,
    // DISCOUNT
    this.discountPercentage,
    this.discountAmount,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
  });

  final CouponType type;
  final String title;
  final String? description;
  final String? imageUrl;
  final int pointsCost;
  final DateTime startDate;
  final DateTime endDate;
  final CouponStatus status;
  final CouponVisibility visibility;
  final String? termsAndConditions;
  final bool? isFeatured;
  final int? sortOrder;
  final int? totalRedemptionLimit;
  final int? perCustomerRedemptionLimit;
  // FREE_PRODUCT
  final int? categoryId;
  final int? productId;
  final int? variantId;
  final int? quantity;
  // DISCOUNT
  final double? discountPercentage;
  final double? discountAmount;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;

  String _formatDate(DateTime dt) => dt.toUtc().toIso8601String();

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{
      'type': type.backendValue,
      'title': title.trim(),
      'pointsCost': pointsCost,
      'startDate': _formatDate(startDate),
      'endDate': _formatDate(endDate),
      'status': status.backendValue,
      'visibility': visibility.backendValue,
    };

    if (description != null && description!.trim().isNotEmpty) {
      body['description'] = description!.trim();
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      body['imageUrl'] = imageUrl;
    }
    if (termsAndConditions != null && termsAndConditions!.trim().isNotEmpty) {
      body['termsAndConditions'] = termsAndConditions!.trim();
    }
    if (isFeatured != null) body['isFeatured'] = isFeatured;
    if (sortOrder != null) body['sortOrder'] = sortOrder;
    if (totalRedemptionLimit != null) {
      body['totalRedemptionLimit'] = totalRedemptionLimit;
    }
    if (perCustomerRedemptionLimit != null) {
      body['perCustomerRedemptionLimit'] = perCustomerRedemptionLimit;
    }

    if (type == CouponType.freeProduct) {
      if (categoryId != null) body['categoryId'] = categoryId;
      if (productId != null) body['productId'] = productId;
      if (variantId != null) body['variantId'] = variantId;
      body['quantity'] = quantity ?? 1;
    }

    if (type == CouponType.percentageDiscount) {
      if (discountPercentage != null) {
        body['discountPercentage'] = discountPercentage;
      }
      if (minimumOrderAmount != null) {
        body['minimumOrderAmount'] = minimumOrderAmount;
      }
      if (maximumDiscountAmount != null) {
        body['maximumDiscountAmount'] = maximumDiscountAmount;
      }
    }

    if (type == CouponType.fixedAmountDiscount) {
      if (discountAmount != null) body['discountAmount'] = discountAmount;
      if (minimumOrderAmount != null) {
        body['minimumOrderAmount'] = minimumOrderAmount;
      }
    }

    return body;
  }
}

class CouponStatusUpdateRequest {
  const CouponStatusUpdateRequest(this.status);
  final String status;

  Map<String, dynamic> toJson() => {'status': status};
}
