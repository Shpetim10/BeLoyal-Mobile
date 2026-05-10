// DTOs for GET /api/besahub/customer/home and related endpoints.

int _asInt(dynamic value, [int fallback = 0]) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
  }
  return fallback;
}

double? _asDoubleOrNull(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value is bool) {
    return value;
  }
  if (value is num) {
    return value != 0;
  }
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}

String _asString(dynamic value, [String fallback = '']) {
  if (value == null) {
    return fallback;
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val));
  }
  return const <String, dynamic>{};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

class CustomerSummaryDto {
  const CustomerSummaryDto({
    required this.currentPoints,
    required this.lifetimePoints,
    required this.spentPoints,
    required this.businessesVisited,
    required this.activeCoupons,
    required this.activeRewards,
    required this.memberSinceLabel,
    required this.memberCode,
  });

  final int currentPoints;
  final int lifetimePoints;
  final int spentPoints;
  final int businessesVisited;
  final int activeCoupons;
  final int activeRewards;
  final String memberSinceLabel;
  final String memberCode;

  factory CustomerSummaryDto.fromJson(Map<String, dynamic> json) {
    return CustomerSummaryDto(
      currentPoints: _asInt(json['currentPoints']),
      lifetimePoints: _asInt(json['lifetimePoints']),
      spentPoints: _asInt(json['spentPoints']),
      businessesVisited: _asInt(json['businessesVisited']),
      activeCoupons: _asInt(json['activeCoupons']),
      activeRewards: _asInt(json['activeRewards']),
      memberSinceLabel: _asString(json['memberSinceLabel']),
      memberCode: _asString(json['memberCode']),
    );
  }
}

class CustomerCategoryDto {
  const CustomerCategoryDto({
    required this.id,
    required this.key,
    required this.label,
    required this.businessCount,
    required this.sortOrder,
  });

  final int id;
  final String key;
  final String label;
  final int businessCount;
  final int sortOrder;

  factory CustomerCategoryDto.fromJson(Map<String, dynamic> json) {
    return CustomerCategoryDto(
      id: _asInt(json['id']),
      key: _asString(json['key']),
      label: _asString(json['label']),
      businessCount: _asInt(json['businessCount']),
      sortOrder: _asInt(json['sortOrder']),
    );
  }
}

class CustomerBusinessDto {
  const CustomerBusinessDto({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryKey,
    required this.categoryLabel,
    required this.points,
    required this.nextRewardPoints,
    required this.hasLogo,
    required this.hasOffer,
    this.rating,
    this.isOpen,
    this.logoUrl,
    this.brandColorHex,
    this.gradientHex,
    this.address,
    this.phone,
    this.email,
    this.description,
    this.offerLabel,
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryKey;
  final String categoryLabel;
  final int points;
  final int nextRewardPoints;
  final bool hasLogo;
  final bool hasOffer;
  final double? rating;
  final bool? isOpen;
  final String? logoUrl;
  final String? brandColorHex;
  final String? gradientHex;
  final String? address;
  final String? phone;
  final String? email;
  final String? description;
  final String? offerLabel;

  factory CustomerBusinessDto.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessDto(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      categoryId: _asInt(json['categoryId']),
      categoryKey: _asString(json['categoryKey']),
      categoryLabel: _asString(json['categoryLabel']),
      points: _asInt(json['points']),
      nextRewardPoints: _asInt(json['nextRewardPoints'], 1),
      hasLogo: _asBool(json['hasLogo']),
      hasOffer: _asBool(json['hasOffer']),
      rating: _asDoubleOrNull(json['rating']),
      isOpen: json['isOpen'] == null ? null : _asBool(json['isOpen']),
      logoUrl: json['logoUrl']?.toString(),
      brandColorHex: json['brandColorHex']?.toString(),
      gradientHex: json['gradientHex']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      description: json['description']?.toString(),
      offerLabel: json['offerLabel']?.toString(),
    );
  }
}

class CustomerPromotionDto {
  const CustomerPromotionDto({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.promotionType,
    required this.status,
    required this.discountDisplay,
    required this.pointCost,
    required this.isHot,
    required this.isUsed,
    required this.isOwned,
    required this.hasOwnershipSignal,
    required this.usageCount,
    required this.isFeatured,
    required this.totalRedemptions,
    this.customerCouponId,
    this.discountValue,
    this.usageLimit,
    this.expiresAt,
    this.termsAndConditions,
    this.imageUrl,
    this.currency,
    this.totalRedemptionLimit,
    this.startDate,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.freeProductCategory,
    this.freeProductName,
    this.freeProductVariant,
    this.freeProductQuantity,
    this.redeemedAt,
    this.usedAt,
    this.orderId,
  });

  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final String description;
  final String promotionType;
  final String status;
  final String discountDisplay;
  final int pointCost;
  final bool isHot;
  final bool isUsed;
  final bool isOwned;
  final bool hasOwnershipSignal;
  final int usageCount;
  final bool isFeatured;
  final int totalRedemptions;
  // customerCouponId is the customer-specific coupon record ID; used for redeem/use endpoints
  final int? customerCouponId;
  final double? discountValue;
  final int? usageLimit;
  final String? expiresAt;
  final String? termsAndConditions;
  final String? imageUrl;
  final String? currency;
  final int? totalRedemptionLimit;
  final String? startDate;
  final double? minimumOrderAmount;
  final double? maximumDiscountAmount;
  final String? freeProductCategory;
  final String? freeProductName;
  final String? freeProductVariant;
  final int? freeProductQuantity;
  final String? redeemedAt;
  final String? usedAt;
  final String? orderId;

  factory CustomerPromotionDto.fromJson(Map<String, dynamic> json) {
    final hasOwnershipSignal =
        json.containsKey('isOwned') ||
        json.containsKey('ownedByCustomer') ||
        json.containsKey('belongsToCustomer') ||
        json.containsKey('claimedByCustomer');

    return CustomerPromotionDto(
      id: _asInt(json['id']),
      businessId: _asInt(json['businessId']),
      businessName: _asString(json['businessName']),
      title: _asString(json['title']),
      description: _asString(json['description']),
      promotionType: _asString(json['promotionType'], 'FREE_PRODUCT'),
      status: _asString(json['status'], 'ACTIVE'),
      discountDisplay: _asString(json['discountDisplay']),
      pointCost: _asInt(json['pointCost']),
      isHot: _asBool(json['isHot']),
      isUsed: _asBool(json['isUsed']),
      isOwned:
          _asBool(json['isOwned']) ||
          _asBool(json['ownedByCustomer']) ||
          _asBool(json['belongsToCustomer']) ||
          _asBool(json['claimedByCustomer']),
      hasOwnershipSignal: hasOwnershipSignal,
      usageCount: _asInt(json['usageCount']),
      isFeatured: _asBool(json['isFeatured']),
      totalRedemptions: _asInt(json['totalRedemptions']),
      customerCouponId: json['customerCouponId'] == null
          ? null
          : _asInt(json['customerCouponId']),
      discountValue: _asDoubleOrNull(json['discountValue']),
      usageLimit: json['usageLimit'] == null
          ? null
          : _asInt(json['usageLimit']),
      expiresAt: json['expiresAt']?.toString(),
      termsAndConditions: json['termsAndConditions']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      currency: json['currency']?.toString(),
      totalRedemptionLimit: json['totalRedemptionLimit'] == null
          ? null
          : _asInt(json['totalRedemptionLimit']),
      startDate: json['startDate']?.toString(),
      minimumOrderAmount: _asDoubleOrNull(json['minimumOrderAmount']),
      maximumDiscountAmount: _asDoubleOrNull(json['maximumDiscountAmount']),
      freeProductCategory: json['freeProductCategory']?.toString(),
      freeProductName: json['freeProductName']?.toString(),
      freeProductVariant: json['freeProductVariant']?.toString(),
      freeProductQuantity: json['freeProductQuantity'] == null
          ? null
          : _asInt(json['freeProductQuantity']),
      redeemedAt: json['redeemedAt']?.toString(),
      usedAt: json['usedAt']?.toString(),
      orderId: json['orderId']?.toString(),
    );
  }
}

class CustomerTransactionDto {
  const CustomerTransactionDto({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.type,
    required this.points,
    required this.date,
    required this.description,
    this.netAmount,
    this.billAmount,
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
  final String date;
  final String description;
  final double? netAmount;
  final double? billAmount;
  final String? referenceId;
  final double? discountAmount;
  final String? invoiceReference;
  final String? note;
  final String? reason;
  final String? scanMethod;
  final double? moneyAmount;
  final double? ruleAmountPer;
  final int? rulePointsPer;

  factory CustomerTransactionDto.fromJson(Map<String, dynamic> json) {
    return CustomerTransactionDto(
      id: _asInt(json['id']),
      businessId: _asInt(json['businessId']),
      businessName: _asString(json['businessName']),
      type: _asString(json['type'], 'EARN'),
      points: _asInt(json['points']),
      date: _asString(json['date']),
      description: _asString(json['description']),
      netAmount: _asDoubleOrNull(json['netAmount']),
      billAmount: _asDoubleOrNull(json['billAmount']),
      referenceId: json['referenceId']?.toString(),
      discountAmount: _asDoubleOrNull(json['discountAmount']),
      invoiceReference: json['invoiceReference']?.toString(),
      note: json['note']?.toString(),
      reason: json['reason']?.toString(),
      scanMethod: json['scanMethod']?.toString(),
      moneyAmount: _asDoubleOrNull(json['moneyAmount']),
      ruleAmountPer: _asDoubleOrNull(json['ruleAmountPer']),
      rulePointsPer: json['rulePointsPer'] == null
          ? null
          : _asInt(json['rulePointsPer']),
    );
  }
}

class CustomerHomeDto {
  const CustomerHomeDto({
    required this.summary,
    required this.categories,
    required this.businesses,
    required this.promotions,
    required this.transactions,
  });

  final CustomerSummaryDto summary;
  final List<CustomerCategoryDto> categories;
  final List<CustomerBusinessDto> businesses;
  final List<CustomerPromotionDto> promotions;
  final List<CustomerTransactionDto> transactions;

  factory CustomerHomeDto.fromJson(Map<String, dynamic> json) {
    return CustomerHomeDto(
      summary: CustomerSummaryDto.fromJson(_asMap(json['summary'])),
      categories: _asList(
        json['categories'],
      ).map((e) => CustomerCategoryDto.fromJson(_asMap(e))).toList(),
      businesses: _asList(
        json['businesses'],
      ).map((e) => CustomerBusinessDto.fromJson(_asMap(e))).toList(),
      promotions: _asList(
        json['promotions'],
      ).map((e) => CustomerPromotionDto.fromJson(_asMap(e))).toList(),
      transactions: _asList(
        json['transactions'],
      ).map((e) => CustomerTransactionDto.fromJson(_asMap(e))).toList(),
    );
  }
}

// ─── Business Detail DTOs (GET /customer/businesses/{businessId}) ─────────────

class CustomerBusinessLocationDto {
  const CustomerBusinessLocationDto({
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

  factory CustomerBusinessLocationDto.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessLocationDto(
      addressLine1: _asString(json['addressLine1']),
      addressLine2: _asString(json['addressLine2']),
      city: _asString(json['city']),
      country: _asString(json['country']),
      postalCode: _asString(json['postalCode']),
      mapLabel: _asString(json['mapLabel']),
      latitude: _asDoubleOrNull(json['latitude']),
      longitude: _asDoubleOrNull(json['longitude']),
    );
  }

  static const empty = CustomerBusinessLocationDto(
    addressLine1: '',
    addressLine2: '',
    city: '',
    country: '',
    postalCode: '',
    mapLabel: '',
  );
}

class CustomerBusinessInfoDto {
  const CustomerBusinessInfoDto({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryKey,
    required this.categoryLabel,
    required this.hasLogo,
    required this.location,
    this.rating,
    this.logoUrl,
    this.brandColorHex,
    this.gradientHex,
    this.description,
    this.address,
    this.phone,
    this.email,
    this.websiteUrl,
  });

  final int id;
  final String name;
  final int categoryId;
  final String categoryKey;
  final String categoryLabel;
  final bool hasLogo;
  final CustomerBusinessLocationDto location;
  final double? rating;
  final String? logoUrl;
  final String? brandColorHex;
  final String? gradientHex;
  final String? description;
  final String? address;
  final String? phone;
  final String? email;
  final String? websiteUrl;

  factory CustomerBusinessInfoDto.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessInfoDto(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      categoryId: _asInt(json['categoryId']),
      categoryKey: _asString(json['categoryKey']),
      categoryLabel: _asString(json['categoryLabel']),
      hasLogo: _asBool(json['hasLogo']),
      location: json['location'] != null
          ? CustomerBusinessLocationDto.fromJson(_asMap(json['location']))
          : CustomerBusinessLocationDto.empty,
      rating: _asDoubleOrNull(json['rating']),
      logoUrl: json['logoUrl']?.toString(),
      brandColorHex: json['brandColorHex']?.toString(),
      gradientHex: json['gradientHex']?.toString(),
      description: json['description']?.toString(),
      address: json['address']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      websiteUrl: json['websiteUrl']?.toString(),
    );
  }
}

class CustomerLoyaltyDetailDto {
  const CustomerLoyaltyDetailDto({
    required this.currentPoints,
    required this.nextRewardPoints,
    required this.pointsToNextReward,
    required this.memberCode,
    required this.loyaltyPolicy,
    required this.minPointsToRedeem,
    required this.pointsPer,
    required this.amountPer,
    required this.lifetimeEarned,
    required this.lifetimeRedeemed,
    required this.lifetimeExpired,
    this.maxPointsToRedeem,
    this.pointsPerUnitDiscount,
    this.maxPointsPerTransaction,
    this.expiryType,
    this.monthsToExpire,
    this.lastActivityAt,
  });

  final int currentPoints;
  final int nextRewardPoints;
  final int pointsToNextReward;
  final String memberCode;
  final String loyaltyPolicy;
  final int minPointsToRedeem;
  final int? maxPointsToRedeem;
  final double? pointsPerUnitDiscount;
  final int? maxPointsPerTransaction;
  final String? expiryType;
  final int? monthsToExpire;
  final int pointsPer;
  final double amountPer;
  final int lifetimeEarned;
  final int lifetimeRedeemed;
  final int lifetimeExpired;
  final String? lastActivityAt;

  factory CustomerLoyaltyDetailDto.fromJson(Map<String, dynamic> json) {
    return CustomerLoyaltyDetailDto(
      currentPoints: _asInt(json['currentPoints']),
      nextRewardPoints: _asInt(json['nextRewardPoints'], 1),
      pointsToNextReward: _asInt(json['pointsToNextReward']),
      memberCode: _asString(json['memberCode']),
      loyaltyPolicy: _asString(json['loyaltyPolicy']),
      minPointsToRedeem: _asInt(json['minPointsToRedeem']),
      maxPointsToRedeem: json['maxPointsToRedeem'] == null
          ? null
          : _asInt(json['maxPointsToRedeem']),
      pointsPerUnitDiscount: _asDoubleOrNull(json['pointsPerUnitDiscount']),
      maxPointsPerTransaction: json['maxPointsPerTransaction'] == null
          ? null
          : _asInt(json['maxPointsPerTransaction']),
      expiryType: json['expiryType']?.toString(),
      monthsToExpire: json['monthsToExpire'] == null
          ? null
          : _asInt(json['monthsToExpire']),
      pointsPer: _asInt(json['pointsPer'], 1),
      amountPer: _asDoubleOrNull(json['amountPer']) ?? 1.0,
      lifetimeEarned: _asInt(json['lifetimeEarned']),
      lifetimeRedeemed: _asInt(json['lifetimeRedeemed']),
      lifetimeExpired: _asInt(json['lifetimeExpired']),
      lastActivityAt: json['lastActivityAt']?.toString(),
    );
  }
}

class CustomerCatalogCategoryDto {
  const CustomerCatalogCategoryDto({
    required this.id,
    required this.name,
    required this.description,
    required this.sortOrder,
  });

  final int id;
  final String name;
  final String description;
  final int sortOrder;

  factory CustomerCatalogCategoryDto.fromJson(Map<String, dynamic> json) {
    return CustomerCatalogCategoryDto(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      sortOrder: _asInt(json['sortOrder']),
    );
  }
}

class CustomerCatalogItemDto {
  const CustomerCatalogItemDto({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.description,
    required this.isPopular,
    required this.isAvailable,
    required this.sortOrder,
    required this.currency,
    required this.unit,
    this.imageUrl,
    this.emoji,
    this.pointsLabel,
    this.basePrice,
  });

  final int id;
  final int categoryId;
  final String name;
  final String description;
  final bool isPopular;
  final bool isAvailable;
  final int sortOrder;
  final String currency;
  final String unit;
  final String? imageUrl;
  final String? emoji;
  final String? pointsLabel;
  final double? basePrice;

  factory CustomerCatalogItemDto.fromJson(Map<String, dynamic> json) {
    return CustomerCatalogItemDto(
      id: _asInt(json['id']),
      categoryId: _asInt(json['categoryId']),
      name: _asString(json['name']),
      description: _asString(json['description']),
      isPopular: _asBool(json['isPopular']),
      isAvailable: _asBool(json['isAvailable'], true),
      sortOrder: _asInt(json['sortOrder']),
      currency: _asString(json['currency'], 'ALL'),
      unit: _asString(json['unit']),
      imageUrl: json['imageUrl']?.toString(),
      emoji: json['emoji']?.toString(),
      pointsLabel: json['pointsLabel']?.toString(),
      basePrice: _asDoubleOrNull(json['basePrice']),
    );
  }
}

class CustomerCatalogVariantDto {
  const CustomerCatalogVariantDto({
    required this.id,
    required this.itemId,
    required this.name,
    required this.price,
    required this.currency,
    required this.isDefault,
    required this.isAvailable,
    required this.description,
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

  factory CustomerCatalogVariantDto.fromJson(Map<String, dynamic> json) {
    return CustomerCatalogVariantDto(
      id: _asInt(json['id']),
      itemId: _asInt(json['itemId']),
      name: _asString(json['name']),
      price: _asDoubleOrNull(json['price']) ?? 0.0,
      currency: _asString(json['currency'], 'ALL'),
      isDefault: _asBool(json['isDefault']),
      isAvailable: _asBool(json['isAvailable'], true),
      description: _asString(json['description']),
      sku: json['sku']?.toString(),
      earnedPoints: json['earnedPoints'] == null
          ? null
          : _asInt(json['earnedPoints']),
    );
  }
}

class CustomerCatalogDto {
  const CustomerCatalogDto({
    required this.categories,
    required this.items,
    required this.variants,
  });

  final List<CustomerCatalogCategoryDto> categories;
  final List<CustomerCatalogItemDto> items;
  final List<CustomerCatalogVariantDto> variants;

  factory CustomerCatalogDto.fromJson(Map<String, dynamic> json) {
    return CustomerCatalogDto(
      categories: _asList(
        json['categories'],
      ).map((e) => CustomerCatalogCategoryDto.fromJson(_asMap(e))).toList(),
      items: _asList(
        json['items'],
      ).map((e) => CustomerCatalogItemDto.fromJson(_asMap(e))).toList(),
      variants: _asList(
        json['variants'],
      ).map((e) => CustomerCatalogVariantDto.fromJson(_asMap(e))).toList(),
    );
  }
}

class CustomerBusinessDetailsInfoDto {
  const CustomerBusinessDetailsInfoDto({
    required this.about,
    required this.phone,
    required this.email,
    required this.categoryLabel,
    required this.customerNotes,
    required this.termsSummary,
    this.websiteUrl,
  });

  final String about;
  final String phone;
  final String email;
  final String categoryLabel;
  final String customerNotes;
  final String termsSummary;
  final String? websiteUrl;

  factory CustomerBusinessDetailsInfoDto.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessDetailsInfoDto(
      about: _asString(json['about']),
      phone: _asString(json['phone']),
      email: _asString(json['email']),
      categoryLabel: _asString(json['categoryLabel']),
      customerNotes: _asString(json['customerNotes']),
      termsSummary: _asString(json['termsSummary']),
      websiteUrl: json['websiteUrl']?.toString(),
    );
  }
}

class CustomerBusinessDetailDto {
  const CustomerBusinessDetailDto({
    required this.business,
    required this.loyalty,
    required this.catalog,
    required this.coupons,
    required this.transactions,
    required this.details,
  });

  final CustomerBusinessInfoDto business;
  final CustomerLoyaltyDetailDto loyalty;
  final CustomerCatalogDto catalog;
  final List<CustomerPromotionDto> coupons;
  final List<CustomerTransactionDto> transactions;
  final CustomerBusinessDetailsInfoDto details;

  factory CustomerBusinessDetailDto.fromJson(Map<String, dynamic> json) {
    return CustomerBusinessDetailDto(
      business: CustomerBusinessInfoDto.fromJson(_asMap(json['business'])),
      loyalty: CustomerLoyaltyDetailDto.fromJson(_asMap(json['loyalty'])),
      catalog: CustomerCatalogDto.fromJson(_asMap(json['catalog'])),
      coupons: _asList(
        json['coupons'],
      ).map((e) => CustomerPromotionDto.fromJson(_asMap(e))).toList(),
      transactions: _asList(
        json['transactions'],
      ).map((e) => CustomerTransactionDto.fromJson(_asMap(e))).toList(),
      details: CustomerBusinessDetailsInfoDto.fromJson(_asMap(json['details'])),
    );
  }
}
