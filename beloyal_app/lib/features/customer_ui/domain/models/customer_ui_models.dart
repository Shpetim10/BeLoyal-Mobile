import 'package:flutter/material.dart';
import '../../../../core/utils/currency_utils.dart';

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
    required this.couponId,
    required this.sourceId,
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
    this.expiresIn,
    this.termsAndConditions = '',
    this.usageLimit,
    this.usageCount = 0,
    this.customerRedemptionCount = 0,
    this.isHot = false,
    this.multiplierLabel,
    this.isOwned = false,
    this.imageUrl,
    this.currency,
    this.isFeatured = false,
    this.totalRedemptions = 0,
    this.totalRedemptionLimit,
    this.startDate,
    this.customerCouponId,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.freeProductCategoryId,
    this.freeProductCategory,
    this.freeProductId,
    this.freeProductName,
    this.freeVariantId,
    this.freeProductVariant,
    this.freeProductQuantity,
    this.redeemedAt,
    this.usedAt,
    this.orderId,
    this.qrCode,
    this.canRedeem,
    this.cannotRedeemReason,
    this.cannotRedeemCode,
    this.currencyCode,
    this.currencySymbol,
    this.canUse,
    this.cannotUseReason,
  });

  // Underlying loyalty coupon id. Used for redeem / validate / detail endpoints.
  final int couponId;
  // Raw `id` value from the source row (e.g. CustomerCoupon row id for owned
  // /my-coupons rows, coupon id for public /promotions rows). Kept for stable
  // list keys; never use this for backend redeem/validate calls.
  final int sourceId;
  final int businessId;
  final String businessName;
  final String title;
  final double discountValue;
  final String discountDisplay;
  final String status;
  final DateTime? expiresAt;
  final int pointCost;
  final List<Color> gradientColors;
  final String type;
  final bool isUsed;
  final String description;
  final String? expiresIn;
  final String termsAndConditions;
  // usageLimit: per-customer purchase cap (null = unlimited).
  final int? usageLimit;
  // usageCount: scan/use count for a specific owned coupon instance.
  final int usageCount;
  // customerRedemptionCount: how many times THIS customer has purchased this coupon.
  final int customerRedemptionCount;
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
  // Free product fields — only populated when type = FREE_PRODUCT.
  final int? freeProductCategoryId;
  final String? freeProductCategory;
  final int? freeProductId;
  final String? freeProductName;
  final int? freeVariantId;
  final String? freeProductVariant;
  final int? freeProductQuantity;
  final DateTime? redeemedAt;
  final DateTime? usedAt;
  final String? orderId;
  // UUID QR code returned by the backend after redemption or from my-coupons list
  final String? qrCode;
  // Backend-computed gate from the available-coupons endpoint.
  final bool? canRedeem;
  final String? cannotRedeemReason;
  // Machine-readable gate code: INSUFFICIENT_POINTS, SOLD_OUT, PER_CUSTOMER_LIMIT, TEMPLATE_INACTIVE
  final String? cannotRedeemCode;
  // Structured currency fields — prefer currencySymbol over code for display.
  final String? currencyCode;
  final String? currencySymbol;
  // Backend gate for whether this owned instance can be used at checkout.
  final bool? canUse;
  final String? cannotUseReason;

  // Prefer backend-provided symbol; fall back to currency code (converted by utility).
  String get displayCurrencySymbol => (currencySymbol?.isNotEmpty == true)
      ? currencySymbol!
      : (currencyCode ?? currency ?? '');

  bool get isFreeProduct => type == 'FREE_PRODUCT';
  bool get isDiscountCoupon =>
      type == 'PERCENTAGE_DISCOUNT' || type == 'FIXED_AMOUNT_DISCOUNT';
  // QR is only meaningful for active/expiring owned instances with a valid
  // owned-instance ID. Expired, used, or backend-gated (canUse=false) coupons
  // must not show the QR as a usable action.
  bool get canShowQr {
    if (!isOwned) return false;
    if (customerCouponId == null) return false;
    if (isUsed) return false;
    if (qrCode == null || qrCode!.isEmpty) return false;
    if (canUse == false) return false;
    return status == CustomerCouponStatus.active ||
        status == CustomerCouponStatus.expiring;
  }

  // True when the coupon is owned and in a usable (active/expiring, not yet used) state.
  bool get isUsable {
    if (!isOwned || isUsed) return false;
    final s = status.toLowerCase();
    return s == 'active' || s == 'expiring';
  }

  // True when an unowned coupon can be claimed with points.
  bool get canClaim {
    if (isOwned) return false;
    if (canRedeem == false) return false;
    if (isLimitReached) return false;
    final s = status.toLowerCase();
    return s == 'active' || s == 'expiring';
  }

  // Per-customer limit is checked against customerRedemptionCount (total purchases by this
  // customer for this coupon template), NOT usageCount (which tracks scans of one instance).
  bool get isPerCustomerLimitReached =>
      usageLimit != null && customerRedemptionCount >= usageLimit!;
  bool get isOverallLimitReached =>
      totalRedemptionLimit != null && totalRedemptions >= totalRedemptionLimit!;
  bool get isLimitReached => isPerCustomerLimitReached || isOverallLimitReached;

  bool get canBuyMore {
    if (isLimitReached) return false;
    // Trust the backend canRedeem gate for both owned and unowned: it reflects
    // template availability, point balance, and per-customer limits — NOT whether
    // this specific instance has already been redeemed/used at the business.
    if (canRedeem == false) return false;
    final s = status.toLowerCase();
    // An owned instance whose status is 'used' can be repurchased when the backend
    // confirms canRedeem=true above (enough points, within limits, template active).
    if (isOwned && (isUsed || s == CustomerCouponStatus.used)) return true;
    return s == CustomerCouponStatus.active ||
        s == CustomerCouponStatus.expiring;
  }

  String get limitReachedReason {
    if (cannotRedeemReason?.isNotEmpty == true) return cannotRedeemReason!;
    if (isPerCustomerLimitReached) {
      return 'You\'ve reached your personal limit for this coupon';
    }
    if (isOverallLimitReached) return 'This coupon is sold out';
    return 'No more coupons available';
  }

  // Human-friendly "X of Y purchased" label using the authoritative redemption count.
  String? get redemptionCountLabel {
    if (usageLimit == null) return null;
    return '$customerRedemptionCount of $usageLimit purchased';
  }

  String get expiryLabel {
    final exp = expiresAt;
    if (exp == null) return 'No expiry provided';
    final expiresInLabel = expiresIn;
    if (expiresInLabel != null && expiresInLabel.isNotEmpty) {
      return expiresInLabel;
    }
    final now = DateTime.now();
    if (exp.isBefore(now)) {
      return 'Expired ${now.difference(exp).inDays}d ago';
    }
    final hours = exp.difference(now).inHours;
    return hours < 24
        ? 'Expires in ${hours}h'
        : 'Expires in ${exp.difference(now).inDays}d';
  }
}

// Canonical UI status values used after normalization.
class CustomerCouponStatus {
  static const active = 'active';
  static const expiring = 'expiring';
  static const used = 'used';
  static const expired = 'expired';
  static const cancelled = 'cancelled';
}

// Canonical UI coupon type values used after normalization.
class CustomerCouponType {
  static const freeProduct = 'FREE_PRODUCT';
  static const percentageDiscount = 'PERCENTAGE_DISCOUNT';
  static const fixedAmountDiscount = 'FIXED_AMOUNT_DISCOUNT';

  /// Maps any backend variant (`DISCOUNT_PERCENT`, `DISCOUNT_FIXED`, lowercase,
  /// etc.) to canonical UI type.
  static String canonical(String raw) {
    final v = raw.trim().toUpperCase();
    switch (v) {
      case 'FREE_PRODUCT':
        return freeProduct;
      case 'PERCENTAGE_DISCOUNT':
      case 'DISCOUNT_PERCENT':
        return percentageDiscount;
      case 'FIXED_AMOUNT_DISCOUNT':
      case 'DISCOUNT_FIXED':
        return fixedAmountDiscount;
      default:
        return v.isEmpty ? freeProduct : v;
    }
  }
}

/// Normalizes any backend coupon/customer-coupon status string into one of the
/// canonical UI statuses. `REDEEMED` becomes `active`, and is upgraded to
/// `expiring` when `expiresAt` is within 3 days.
String canonicalCouponStatus(String raw, {DateTime? expiresAt}) {
  final v = raw.trim().toLowerCase();
  final now = DateTime.now();

  switch (v) {
    case 'used':
      return CustomerCouponStatus.used;
    case 'expired':
      return CustomerCouponStatus.expired;
    case 'cancelled':
    case 'canceled':
      return CustomerCouponStatus.cancelled;
    case 'expiring':
      return CustomerCouponStatus.expiring;
    case 'redeemed':
    case 'active':
    case 'draft':
    case 'paused':
    case 'archived':
    default:
      if (expiresAt != null) {
        if (expiresAt.isBefore(now)) return CustomerCouponStatus.expired;
        if (expiresAt.isBefore(now.add(const Duration(days: 3)))) {
          return CustomerCouponStatus.expiring;
        }
      }
      return CustomerCouponStatus.active;
  }
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
    this.currency,
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

  /// Currency code for this transaction (e.g. 'ALL', 'EUR'). Null falls back to 'ALL'.
  final String? currency;
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
    return formatCurrencyWithSymbol(price, currency);
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
    this.earnedPoints,
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
  final int? earnedPoints;

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
    this.currency = 'ALL',
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

  /// Currency code for this business (e.g. 'ALL', 'EUR', 'USD'). Defaults to 'ALL'.
  final String currency;
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
    final sym = currencySymbol(currency);
    return 'Earn $pointsPer pts per ${amountPer.toStringAsFixed(0)} $sym spent';
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
