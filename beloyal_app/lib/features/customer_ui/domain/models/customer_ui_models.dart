import 'package:flutter/material.dart';

class CustomerCategory {
  const CustomerCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.businessCount,
    this.hasBonus = false,
  });

  final int id;
  final String name;
  final IconData icon;
  final Color color;
  final int businessCount;
  final bool hasBonus;
}

class CustomerBusiness {
  const CustomerBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.gradientColors,
    required this.points,
    required this.nextRewardPoints,
    required this.isOpen,
    required this.rating,
    required this.logoEmoji,
    required this.address,
    required this.phone,
    required this.email,
    this.distance = 'Unavailable',
    this.hasOffer = false,
    this.offerLabel,
    this.description = '',
    this.hasLogo = true,
    this.logoUrl,
    this.brandColorHex,
    this.gradientHex,
  });

  final int id;
  final String name;
  final String category;
  final int categoryId;
  final List<Color> gradientColors;
  final int points;
  final int nextRewardPoints;
  final bool isOpen;
  final double rating;
  final String logoEmoji;
  final String address;
  final String phone;
  final String email;
  final String distance;
  final bool hasOffer;
  final String? offerLabel;
  final String description;
  final bool hasLogo;
  final String? logoUrl;
  final String? brandColorHex;
  final String? gradientHex;
}

class CustomerCoupon {
  const CustomerCoupon({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.discountValue,
    required this.discountDisplay,
    required this.status,
    required this.expiresAt,
    required this.pointCost,
    required this.gradientColors,
    required this.type,
    this.isUsed = false,
    this.description = '',
    this.termsAndConditions = '',
    this.usageLimit,
    this.usageCount = 0,
    this.isHot = false,
    this.multiplierLabel,
    this.isOwned = true,
    this.imageUrl,
    this.currency,
    this.isFeatured = false,
    this.totalRedemptions = 0,
    this.totalRedemptionLimit,
    this.startDate,
    this.customerCouponId,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.freeProductCategory,
    this.freeProductName,
    this.freeProductVariant,
    this.freeProductQuantity,
    this.redeemedAt,
    this.usedAt,
    this.orderId,
    this.qrCode,
  });

  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final double discountValue;
  final String discountDisplay;
  final String status;
  final DateTime expiresAt;
  final int pointCost;
  final List<Color> gradientColors;
  final String type;
  final bool isUsed;
  final String description;
  final String termsAndConditions;
  final int? usageLimit;
  final int usageCount;
  final bool isHot;
  final String? multiplierLabel;
  final bool isOwned;
  final String? imageUrl;
  final String? currency;
  final bool isFeatured;
  final int totalRedemptions;
  final int? totalRedemptionLimit;
  final DateTime? startDate;
  // customerCouponId is the customer-owned coupon record; distinct from the template coupon id
  final int? customerCouponId;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final String? freeProductCategory;
  final String? freeProductName;
  final String? freeProductVariant;
  final int? freeProductQuantity;
  final DateTime? redeemedAt;
  final DateTime? usedAt;
  final String? orderId;
  // UUID QR code returned by the backend after redemption or from my-coupons list
  final String? qrCode;

  bool get isFreeProduct => type == 'FREE_PRODUCT';
  bool get isDiscountCoupon =>
      type == 'PERCENTAGE_DISCOUNT' || type == 'FIXED_AMOUNT_DISCOUNT';
  bool get canShowQr =>
      isOwned && !isUsed && qrCode != null && qrCode!.isNotEmpty;
  bool get canClaim => !isOwned;
}

class CustomerReward {
  const CustomerReward({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.pointCost,
    required this.currentPoints,
    required this.gradientColors,
    required this.category,
    required this.logoEmoji,
  });

  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final String description;
  final int pointCost;
  final int currentPoints;
  final List<Color> gradientColors;
  final String category;
  final String logoEmoji;
}

class CustomerTransaction {
  const CustomerTransaction({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.type,
    required this.points,
    required this.date,
    required this.description,
    required this.netAmount,
    required this.billAmount,
    required this.logoEmoji,
    this.referenceId,
    this.discountAmount,
    this.invoiceReference,
    this.note,
    this.reason,
    this.scanMethod,
    this.moneyAmount,
    this.ruleAmountPer,
    this.rulePointsPer,
  });

  final int id;
  final int businessId;
  final String businessName;
  final String type;
  final int points;
  final DateTime date;
  final String description;
  final double netAmount;
  final double billAmount;
  final String logoEmoji;
  final String? referenceId;
  final double? discountAmount;
  final String? invoiceReference;
  final String? note;
  final String? reason;
  final String? scanMethod;
  final double? moneyAmount;
  final double? ruleAmountPer;
  final int? rulePointsPer;
}

class CustomerMenuVariant {
  const CustomerMenuVariant({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.currency,
    required this.isDefault,
    required this.isAvailable,
    this.description = '',
    this.sku,
    this.earnedPoints,
  });

  final int id;
  final int itemId;
  final String name;
  final double price;
  final String currency;
  final bool isDefault;
  final bool isAvailable;
  final String description;
  final String? sku;
  final int? earnedPoints;

  String get formattedPrice {
    final symbol = currency == 'ALL' ? 'L' : currency;
    return '${price.toStringAsFixed(0)} $symbol';
  }
}

class CustomerMenuCategory {
  const CustomerMenuCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String description;
  final int sortOrder;
}

class CustomerBusinessLocation {
  const CustomerBusinessLocation({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.country,
    required this.postalCode,
    required this.mapLabel,
    this.latitude,
    this.longitude,
  });

  final String addressLine1;
  final String addressLine2;
  final String city;
  final String country;
  final String postalCode;
  final String mapLabel;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  String get formattedAddress {
    final parts = [
      if (addressLine1.isNotEmpty) addressLine1,
      if (addressLine2.isNotEmpty) addressLine2,
      if (city.isNotEmpty) city,
      if (postalCode.isNotEmpty) postalCode,
      if (country.isNotEmpty) country,
    ];
    return parts.isEmpty ? mapLabel : parts.join(', ');
  }
}

class CustomerMenuItem {
  const CustomerMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.menuCategory,
    required this.emoji,
    required this.variants,
    this.imageUrl,
    this.pointsLabel = '',
    this.isPopular = false,
    this.isAvailable = true,
    this.basePrice,
    this.baseCurrency = 'ALL',
    this.unit = '',
  });

  final int id;
  final String name;
  final String description;
  final int categoryId;
  final String menuCategory;
  final String emoji;
  final List<CustomerMenuVariant> variants;
  final String? imageUrl;
  final String pointsLabel;
  final bool isPopular;
  final bool isAvailable;
  final double? basePrice;
  final String baseCurrency;
  final String unit;

  double get price {
    if (variants.isEmpty) return 0.0;
    final defaults = variants.where((v) => v.isDefault).toList();
    return defaults.isNotEmpty ? defaults.first.price : variants.first.price;
  }

  String get currency {
    if (variants.isEmpty) return 'ALL';
    final defaults = variants.where((v) => v.isDefault).toList();
    return defaults.isNotEmpty
        ? defaults.first.currency
        : variants.first.currency;
  }
}

class CustomerBusinessDetail {
  const CustomerBusinessDetail({
    required this.businessId,
    required this.loyaltyPolicy,
    required this.currentPoints,
    required this.nextRewardPoints,
    required this.pointsToNextReward,
    required this.memberCode,
    required this.menuCategories,
    required this.menuItems,
    required this.location,
    required this.about,
    required this.coupons,
    required this.transactions,
    required this.phone,
    required this.email,
    required this.categoryLabel,
    required this.minPointsToRedeem,
    required this.pointsPer,
    required this.amountPer,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
    required this.lifetimeExpired,
    this.websiteUrl,
    this.maxPointsToRedeem,
    this.pointsPerUnitDiscount,
    this.maxPointsPerTransaction,
    this.expiryType,
    this.monthsToExpire,
    this.lastActivityAt,
  });

  final int businessId;
  final String loyaltyPolicy;
  final int currentPoints;
  final int nextRewardPoints;
  final int pointsToNextReward;
  final String memberCode;
  final List<CustomerMenuCategory> menuCategories;
  final List<CustomerMenuItem> menuItems;
  final CustomerBusinessLocation location;
  final String about;
  final List<CustomerCoupon> coupons;
  final List<CustomerTransaction> transactions;
  final String phone;
  final String email;
  final String categoryLabel;
  final String? websiteUrl;
  // Loyalty settings
  final int minPointsToRedeem;
  final int? maxPointsToRedeem;
  final double? pointsPerUnitDiscount;
  final int? maxPointsPerTransaction;
  final String? expiryType;
  final int? monthsToExpire;
  final int pointsPer;
  final double amountPer;
  // Lifetime stats
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final int lifetimeExpired;
  final DateTime? lastActivityAt;

  List<CustomerMenuItem> itemsForCategory(int? categoryId) {
    if (categoryId == null) return menuItems;
    return menuItems.where((i) => i.categoryId == categoryId).toList();
  }

  bool get hasEarningRule => pointsPer > 0 && amountPer > 0;

  String get earningRuleLabel {
    if (!hasEarningRule) return '';
    final symbol = 'L';
    return 'Earn $pointsPer pts per ${amountPer.toStringAsFixed(0)} $symbol spent';
  }

  String get expiryLabel {
    if (expiryType == null || expiryType == 'NEVER') {
      return 'Points never expire';
    }
    if (expiryType == 'MONTHLY' && monthsToExpire != null) {
      return 'Points expire after $monthsToExpire month${monthsToExpire == 1 ? '' : 's'}';
    }
    return expiryType ?? '';
  }
}
