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
    this.usageLimit,
    this.expiresAt,
    this.termsAndConditions,
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
  final int? usageLimit;
  final String? expiresAt;
  final String? termsAndConditions;

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
      usageLimit: json['usageLimit'] == null
          ? null
          : _asInt(json['usageLimit']),
      expiresAt: json['expiresAt']?.toString(),
      termsAndConditions: json['termsAndConditions']?.toString(),
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
