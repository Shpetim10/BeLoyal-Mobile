import 'package:flutter/material.dart';
import '../../data/models/customer_home_dto.dart';
import 'customer_ui_models.dart';

// ─── Business detail mapper ───────────────────────────────────────────────────

CustomerBusinessDetail mapBusinessDetailDto(CustomerBusinessDetailDto dto) {
  // Build variant lookup by itemId.
  final variantsByItem = <int, List<CustomerMenuVariant>>{};
  for (final v in dto.catalog.variants) {
    variantsByItem
        .putIfAbsent(v.itemId, () => [])
        .add(
          CustomerMenuVariant(
            id: v.id,
            itemId: v.itemId,
            name: v.name,
            price: v.price,
            currency: v.currency,
            isDefault: v.isDefault,
            isAvailable: v.isAvailable,
            description: v.description,
            sku: v.sku,
            earnedPoints: v.earnedPoints,
          ),
        );
  }

  final menuCategories = dto.catalog.categories
      .map(
        (c) => CustomerMenuCategory(
          id: c.id,
          name: c.name,
          description: c.description,
          sortOrder: c.sortOrder,
        ),
      )
      .toList();

  final catNameById = <int, String>{
    for (final c in menuCategories) c.id: c.name,
  };

  // Include all items; filtering by isAvailable is intentional for the menu tab.
  final menuItems = dto.catalog.items
      .where((i) => i.isAvailable)
      .map(
        (i) => CustomerMenuItem(
          id: i.id,
          name: i.name,
          description: i.description,
          categoryId: i.categoryId,
          menuCategory: catNameById[i.categoryId] ?? '',
          emoji: i.emoji ?? _emojiFromKey(dto.business.categoryKey),
          variants: variantsByItem[i.id] ?? [],
          imageUrl: i.imageUrl,
          pointsLabel: i.pointsLabel ?? '',
          isPopular: i.isPopular,
          isAvailable: i.isAvailable,
          basePrice: i.basePrice,
          baseCurrency: i.currency,
          unit: i.unit,
          earnedPoints: i.earnedPoints,
        ),
      )
      .toList();

  final loc = dto.business.location;
  final location = CustomerBusinessLocation(
    addressLine1: loc.addressLine1,
    addressLine2: loc.addressLine2,
    city: loc.city,
    country: loc.country,
    postalCode: loc.postalCode,
    mapLabel: loc.mapLabel,
    latitude: loc.latitude,
    longitude: loc.longitude,
  );

  final categoryKey = dto.business.categoryKey;
  final bizMap = {dto.business.id: categoryKey};

  final coupons = dto.coupons.map((p) => _mapPromotion(p, bizMap)).toList();

  // Derive business currency early so transactions carry it.
  final businessCurrencyEarly = dto.catalog.variants.isNotEmpty
      ? dto.catalog.variants.first.currency
      : dto.catalog.items.isNotEmpty
      ? dto.catalog.items.first.currency
      : 'ALL';

  final transactions = dto.transactions
      .map((t) => _mapTransaction(t, bizMap, businessCurrencyEarly))
      .toList();

  final loyalty = dto.loyalty;
  final details = dto.details;

  // Prefer websiteUrl from business info, fall back to details
  final websiteUrl = dto.business.websiteUrl?.isNotEmpty == true
      ? dto.business.websiteUrl
      : details.websiteUrl?.isNotEmpty == true
      ? details.websiteUrl
      : null;

  // Prefer phone/email from details (more complete), fall back to business info
  final phone = details.phone.isNotEmpty
      ? details.phone
      : dto.business.phone ?? '';
  final email = details.email.isNotEmpty
      ? details.email
      : dto.business.email ?? '';
  final categoryLabel = details.categoryLabel.isNotEmpty
      ? details.categoryLabel
      : dto.business.categoryLabel;

  return CustomerBusinessDetail(
    businessId: dto.business.id,
    loyaltyPolicy: loyalty.loyaltyPolicy,
    currentPoints: loyalty.currentPoints,
    nextRewardPoints: loyalty.nextRewardPoints,
    pointsToNextReward: loyalty.pointsToNextReward,
    memberCode: loyalty.memberCode,
    menuCategories: menuCategories,
    menuItems: menuItems,
    location: location,
    about: details.about,
    coupons: coupons,
    transactions: transactions,
    phone: phone,
    email: email,
    categoryLabel: categoryLabel,
    websiteUrl: websiteUrl,
    currency: businessCurrencyEarly,
    minPointsToRedeem: loyalty.minPointsToRedeem,
    maxPointsToRedeem: loyalty.maxPointsToRedeem,
    pointsPerUnitDiscount: loyalty.pointsPerUnitDiscount,
    maxPointsPerTransaction: loyalty.maxPointsPerTransaction,
    expiryType: loyalty.expiryType,
    monthsToExpire: loyalty.monthsToExpire,
    pointsPer: loyalty.pointsPer,
    amountPer: loyalty.amountPer,
    lifetimeEarned: loyalty.lifetimeEarned,
    lifetimeRedeemed: loyalty.lifetimeRedeemed,
    lifetimeExpired: loyalty.lifetimeExpired,
    lastActivityAt: loyalty.lastActivityAt != null
        ? DateTime.tryParse(loyalty.lastActivityAt!)
        : null,
  );
}

// ─── CustomerProfile ──────────────────────────────────────────────────────────

class CustomerProfile {
  const CustomerProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.currentPoints,
    required this.lifetimePoints,
    required this.spentPoints,
    required this.businessesVisited,
    required this.activeCoupons,
    required this.activeRewards,
    required this.memberSince,
    required this.memberCode,
    required this.roles,
  });

  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int currentPoints;
  final int lifetimePoints;
  final int spentPoints;
  final int businessesVisited;
  final int activeCoupons;
  final int activeRewards;
  final String memberSince;
  final String memberCode;
  final List<String> roles;

  String get fullName => (firstName.isNotEmpty && lastName.isNotEmpty)
      ? '$firstName $lastName'
      : firstName;

  String get initials {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '${firstName[0]}${lastName[0]}';
    }
    if (firstName.isNotEmpty) {
      return firstName[0];
    }
    return '?';
  }

  String get firstNameOrFallback =>
      firstName.isNotEmpty ? firstName : 'Customer';

  factory CustomerProfile.empty() {
    return const CustomerProfile(
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      currentPoints: 0,
      lifetimePoints: 0,
      spentPoints: 0,
      businessesVisited: 0,
      activeCoupons: 0,
      activeRewards: 0,
      memberSince: '',
      memberCode: '',
      roles: ['Customer'],
    );
  }

  factory CustomerProfile.fromSummaryDto(CustomerSummaryDto dto) {
    return CustomerProfile(
      firstName: '',
      lastName: '',
      email: '',
      phone: '',
      currentPoints: dto.currentPoints,
      lifetimePoints: dto.lifetimePoints,
      spentPoints: dto.spentPoints,
      businessesVisited: dto.businessesVisited,
      activeCoupons: dto.activeCoupons,
      activeRewards: dto.activeRewards,
      memberSince: dto.memberSinceLabel,
      memberCode: dto.memberCode,
      roles: const ['Customer'],
    );
  }
}

// ─── CustomerDataSource ───────────────────────────────────────────────────────

class CustomerDataSource {
  const CustomerDataSource({
    required this.summary,
    required this.categories,
    required this.businesses,
    required this.coupons,
    required this.ownedCoupons,
    required this.rewards,
    required this.transactions,
  });

  final CustomerProfile summary;
  final List<CustomerCategory> categories;
  final List<CustomerBusiness> businesses;
  // Home promotions (template/public view, with deduplication). Used for the
  // "All Coupons" tab, home carousels, and hot offers.
  final List<CustomerCoupon> coupons;
  // Individual owned instances from /my-coupons — each customerCouponId is
  // preserved. No deduplication by couponId; the customer may own several copies.
  final List<CustomerCoupon> ownedCoupons;
  final List<CustomerReward> rewards;
  final List<CustomerTransaction> transactions;

  List<CustomerBusiness> get businessesWithPoints =>
      businesses.where((b) => b.points > 0).toList();

  // Returns each individually-owned coupon instance from /my-coupons so the
  // customer sees every copy they purchased, each with its own QR and status.
  List<CustomerCoupon> get myCoupons => ownedCoupons;

  List<CustomerCoupon> get allCoupons => coupons;

  List<CustomerBusiness> get hotBusinesses =>
      ([...businesses]..sort((a, b) => b.rating.compareTo(a.rating)));

  List<CustomerCoupon> get hotOffers => coupons.where((c) => c.isHot).toList();

  List<CustomerTransaction> get recentActivity => transactions.take(5).toList();

  List<CustomerCoupon> couponsForBusiness(int businessId) =>
      coupons.where((c) => !c.isHot && c.businessId == businessId).toList();

  List<CustomerCoupon> offersForBusiness(int businessId) =>
      coupons.where((c) => c.isHot && c.businessId == businessId).toList();

  List<CustomerReward> rewardsForBusiness(int businessId) =>
      rewards.where((r) => r.businessId == businessId).toList();

  List<CustomerTransaction> transactionsForBusiness(int businessId) =>
      transactions.where((t) => t.businessId == businessId).toList();

  factory CustomerDataSource.empty() {
    return CustomerDataSource(
      summary: CustomerProfile.empty(),
      categories: const [],
      businesses: const [],
      coupons: const [],
      ownedCoupons: const [],
      rewards: const [],
      transactions: const [],
    );
  }

  factory CustomerDataSource.fromDto(
    CustomerHomeDto dto, {
    // Individual owned instances from /my-coupons. Preserved without dedup so
    // each customerCouponId is a separate entry in myCoupons.
    List<CustomerPromotionDto> myCouponDtos = const [],
    // QR override map keyed by couponId — used to attach QR codes to home
    // promotions rows (for backward compat with home screen display).
    Map<int, String> qrCodeOverrides = const {},
  }) {
    final bizCategoryMap = <int, String>{
      for (final b in dto.businesses) b.id: b.categoryKey,
    };

    final businesses = dto.businesses.map(_mapBusiness).toList();

    // Map home promotions (template/public view). QR overrides attach the best
    // available QR to each coupon template row for display on the home screen.
    final rawCoupons = dto.promotions
        .map(
          (p) => _mapPromotion(
            p,
            bizCategoryMap,
            qrCodeOverride: qrCodeOverrides[p.couponId],
          ),
        )
        .toList();

    // Deduplicate home-promotion rows only (template level). This collapses
    // duplicate rows from the home API — it does NOT affect owned instances,
    // which come through myCouponDtos below.
    final homeCoupons = _deduplicateCoupons(rawCoupons);

    // Map each /my-coupons row as an independent owned instance. One customer
    // can own multiple copies of the same coupon (different customerCouponIds),
    // each with its own QR code, expiry, and status — never deduplicate here.
    final ownedCoupons = myCouponDtos
        .map((p) => _mapPromotion(p, bizCategoryMap))
        .toList();

    return CustomerDataSource(
      summary: CustomerProfile.fromSummaryDto(dto.summary),
      categories: dto.categories.map(_mapCategory).toList(),
      businesses: businesses,
      coupons: homeCoupons,
      ownedCoupons: ownedCoupons,
      rewards: businesses.map(_mapRewardFromBusiness).toList(),
      transactions: dto.transactions
          .map((t) => _mapTransaction(t, bizCategoryMap))
          .toList(),
    );
  }
}

// ─── Post-redeem mapper ───────────────────────────────────────────────────────
// Builds an "owned" CustomerCoupon from the /redeem response, preserving fields
// from the source coupon that the response doesn't echo back. Centralized here
// so every redeem call site (rewards tab, detail sheet, view-all) builds the
// same QR coupon shape.
CustomerCoupon buildOwnedCouponFromRedemption(
  CustomerCoupon source,
  CustomerCouponRedemptionDto result,
) {
  final responseExpiresAt = result.expiresAt != null
      ? DateTime.tryParse(result.expiresAt!)
      : null;
  final expiresAt = responseExpiresAt ?? source.expiresAt;
  String? expiresIn;
  if (expiresAt != null) {
    final now = DateTime.now();
    if (expiresAt.isAfter(now)) {
      final hours = expiresAt.difference(now).inHours;
      expiresIn = hours < 24
          ? 'Expires in ${hours}h'
          : 'Expires in ${expiresAt.difference(now).inDays}d';
    }
  }
  final canonicalType = CustomerCouponType.canonical(result.snapshotCouponType);
  final canonicalStatus = canonicalCouponStatus(
    result.status,
    expiresAt: expiresAt,
  );
  return CustomerCoupon(
    couponId: result.couponId,
    sourceId: result.customerCouponId,
    businessId: source.businessId,
    businessName: source.businessName,
    title: result.snapshotTitle.isNotEmpty
        ? result.snapshotTitle
        : source.title,
    discountValue: source.discountValue,
    discountDisplay: source.discountDisplay,
    status: canonicalStatus,
    expiresAt: expiresAt,
    pointCost: result.pointsSpent,
    gradientColors: source.gradientColors,
    type: canonicalType,
    isUsed: false,
    description: result.snapshotDescription.isNotEmpty
        ? result.snapshotDescription
        : source.description,
    expiresIn: expiresIn,
    termsAndConditions: source.termsAndConditions,
    usageLimit: source.usageLimit,
    usageCount: source.usageCount,
    customerRedemptionCount: source.customerRedemptionCount + 1,
    isOwned: true,
    imageUrl: result.snapshotImageUrl ?? source.imageUrl,
    currency: result.currency ?? source.currency,
    customerCouponId: result.customerCouponId,
    isFeatured: source.isFeatured,
    totalRedemptions: source.totalRedemptions + 1,
    totalRedemptionLimit: source.totalRedemptionLimit,
    minimumOrderAmount: source.minimumOrderAmount,
    maximumDiscountAmount: source.maximumDiscountAmount,
    freeProductName: source.freeProductName,
    freeProductVariant: source.freeProductVariant,
    freeProductCategory: source.freeProductCategory,
    freeProductQuantity: source.freeProductQuantity,
    redeemedAt: result.redeemedAt != null
        ? DateTime.tryParse(result.redeemedAt!)
        : DateTime.now(),
    qrCode: result.qrCode.isNotEmpty ? result.qrCode : null,
    currencyCode: result.currency ?? source.currencyCode,
    currencySymbol: source.currencySymbol,
    canUse: null,   // reset — backend will re-compute on next fetch
    cannotUseReason: null,
  );
}

// ─── Mapper helpers ───────────────────────────────────────────────────────────

CustomerCategory _mapCategory(CustomerCategoryDto dto) {
  return CustomerCategory(
    id: dto.id,
    name: dto.label,
    icon: _iconFromKey(dto.key),
    color: _colorFromKey(dto.key),
    businessCount: dto.businessCount,
  );
}

CustomerBusiness _mapBusiness(CustomerBusinessDto dto) {
  final gradientColors = _gradientFromBusiness(dto);
  return CustomerBusiness(
    id: dto.id,
    name: dto.name,
    category: dto.categoryLabel,
    categoryId: dto.categoryId,
    gradientColors: gradientColors,
    points: dto.points,
    nextRewardPoints: dto.nextRewardPoints,
    isOpen: dto.isOpen ?? false,
    rating: dto.rating ?? 0.0,
    logoEmoji: _emojiFromKey(dto.categoryKey),
    address: dto.address ?? '',
    phone: dto.phone ?? '',
    email: dto.email ?? '',
    hasOffer: dto.hasOffer,
    offerLabel: dto.offerLabel,
    description: dto.description ?? '',
    hasLogo: dto.hasLogo,
    logoUrl: dto.logoUrl,
    brandColorHex: dto.brandColorHex,
    gradientHex: dto.gradientHex,
  );
}

List<Color> _gradientFromBusiness(CustomerBusinessDto dto) {
  final fallback = _gradientFromKey(dto.categoryKey);
  final brand = _colorFromHex(dto.brandColorHex);
  final gradient = _colorFromHex(dto.gradientHex);
  if (brand == null && gradient == null) return fallback;
  if (brand != null && gradient != null && brand != gradient) {
    return [brand.withValues(alpha: 0.7), gradient];
  }
  final base = brand ?? gradient!;
  return [base.withValues(alpha: 0.65), base];
}

Color? _colorFromHex(String? hex) {
  if (hex == null) return null;
  final cleaned = hex.trim().replaceAll('#', '');
  if (cleaned.length != 6 && cleaned.length != 8) return null;
  final normalized = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
  final value = int.tryParse(normalized, radix: 16);
  if (value == null) return null;
  return Color(value);
}

CustomerReward _mapRewardFromBusiness(CustomerBusiness business) {
  final remainingPoints = (business.nextRewardPoints - business.points).clamp(
    0,
    business.nextRewardPoints,
  );
  final isUnlocked = remainingPoints == 0;

  return CustomerReward(
    id: business.id,
    businessId: business.id,
    businessName: business.name,
    title: isUnlocked ? 'Reward unlocked' : 'Next reward at ${business.name}',
    description: isUnlocked
        ? 'You have enough points at this business to redeem your next reward.'
        : 'Keep earning points here to unlock the next available reward tier.',
    pointCost: business.nextRewardPoints,
    currentPoints: business.points,
    gradientColors: business.gradientColors,
    category: business.category,
    logoEmoji: business.logoEmoji,
  );
}

// Deduplicates owned coupon instances: when the backend returns multiple
// CustomerCoupon rows for the same template (e.g. one USED + one REDEEMED after
// a repeat purchase), keep the instance with the best status (active > expiring
// > used > expired) so card surfaces show the most actionable state.
// Unowned (public template) rows are kept as-is since they have no instances.
List<CustomerCoupon> _deduplicateCoupons(List<CustomerCoupon> coupons) {
  int statusRank(String s) => switch (s) {
    CustomerCouponStatus.active => 0,
    CustomerCouponStatus.expiring => 1,
    CustomerCouponStatus.used => 2,
    CustomerCouponStatus.expired => 3,
    _ => 4,
  };

  final Map<String, CustomerCoupon> best = {};
  for (final c in coupons) {
    if (!c.isOwned) {
      // Unowned coupons use couponId as their key; never deduplicated.
      final key = 'public_${c.businessId}_${c.couponId}';
      best[key] ??= c;
      continue;
    }
    final key = 'owned_${c.businessId}_${c.couponId}';
    final existing = best[key];
    if (existing == null || statusRank(c.status) < statusRank(existing.status)) {
      best[key] = c;
    }
  }
  return best.values.toList();
}

CustomerCoupon _mapPromotion(
  CustomerPromotionDto dto,
  Map<int, String> bizCategoryMap, {
  String? qrCodeOverride,
}) {
  final categoryKey = bizCategoryMap[dto.businessId] ?? '';
  final expires = dto.expiresAt;
  final expiresIn =
      dto.expiresIn ??
      (expires != null ? _calculateExpiresInTime(expires) : null);
  final canonicalType = CustomerCouponType.canonical(dto.promotionType);
  final canonicalStatus = canonicalCouponStatus(dto.status, expiresAt: expires);

  return CustomerCoupon(
    couponId: dto.couponId,
    sourceId: dto.sourceId,
    businessId: dto.businessId,
    businessName: dto.businessName,
    title: dto.title,
    discountValue: dto.discountValue ?? 0,
    discountDisplay: dto.discountDisplay,
    status: canonicalStatus,
    expiresAt: expires,
    pointCost: dto.pointCost,
    gradientColors: _gradientFromKey(categoryKey),
    type: canonicalType,
    isUsed: dto.isUsed,
    description: dto.description,
    expiresIn: expiresIn,
    termsAndConditions: dto.termsAndConditions ?? '',
    usageLimit: dto.usageLimit,
    usageCount: dto.usageCount,
    customerRedemptionCount: dto.customerRedemptionCount,
    isHot: dto.isHot,
    isOwned: dto.isOwned,
    imageUrl: dto.imageUrl,
    currency: dto.currency,
    isFeatured: dto.isFeatured,
    totalRedemptions: dto.totalRedemptions,
    totalRedemptionLimit: dto.totalRedemptionLimit,
    startDate: DateTime.tryParse(dto.startDate ?? ''),
    customerCouponId: dto.customerCouponId,
    minimumOrderAmount: dto.minimumOrderAmount,
    maximumDiscountAmount: dto.maximumDiscountAmount,
    freeProductCategory: dto.freeProductCategory,
    freeProductName: dto.freeProductName,
    freeProductVariant: dto.freeProductVariant,
    freeProductQuantity: dto.freeProductQuantity,
    redeemedAt: dto.redeemedAt != null
        ? DateTime.tryParse(dto.redeemedAt!)
        : null,
    usedAt: dto.usedAt != null ? DateTime.tryParse(dto.usedAt!) : null,
    orderId: dto.orderId,
    qrCode: (qrCodeOverride?.isNotEmpty == true) ? qrCodeOverride : dto.qrCode,
    canRedeem: dto.canRedeem,
    cannotRedeemReason: dto.cannotRedeemReason,
    currencyCode: dto.currencyCode,
    currencySymbol: dto.currencySymbol,
    canUse: dto.canUse,
    cannotUseReason: dto.cannotUseReason,
  );
}

String _calculateExpiresInTime(DateTime expiresAt) {
  final now = DateTime.now();
  if (expiresAt.isBefore(now)) {
    final daysAgo = now.difference(expiresAt).inDays;
    return 'Expired ${daysAgo}d ago';
  }

  final hoursLeft = expiresAt.difference(now).inHours;
  if (hoursLeft < 24) {
    return 'Expires in ${hoursLeft}h';
  }

  final daysLeft = expiresAt.difference(now).inDays;
  return 'Expires in ${daysLeft}d';
}

CustomerTransaction _mapTransaction(
  CustomerTransactionDto dto,
  Map<int, String> bizCategoryMap, [
  String? currencyFallback,
]) {
  final categoryKey = bizCategoryMap[dto.businessId] ?? '';

  return CustomerTransaction(
    id: dto.id,
    businessId: dto.businessId,
    businessName: dto.businessName,
    type: dto.type,
    points: dto.points,
    date: dto.date,
    description: dto.description,
    netAmount: dto.netAmount ?? 0.0,
    billAmount: dto.billAmount ?? 0.0,
    logoEmoji: _emojiFromKey(categoryKey),
    referenceId: dto.referenceId,
    discountAmount: dto.discountAmount,
    invoiceReference: dto.invoiceReference,
    note: dto.note,
    reason: dto.reason,
    scanMethod: dto.scanMethod,
    moneyAmount: dto.moneyAmount,
    ruleAmountPer: dto.ruleAmountPer,
    rulePointsPer: dto.rulePointsPer,
    currency: dto.currency ?? currencyFallback,
  );
}

// ─── Category-key → visual mappings ──────────────────────────────────────────

Color _colorFromKey(String key) => switch (key) {
  'RESTAURANT' => const Color(0xFFEF4444),
  'CAFE' => const Color(0xFFF59E0B),
  'FITNESS' => const Color(0xFF22C55E),
  'BEAUTY' => const Color(0xFFF15BB5),
  'RETAIL' => const Color(0xFF9B5DE5),
  'GROCERY' => const Color(0xFF00D4FF),
  'ENTERTAINMENT' => const Color(0xFFFF6B35),
  'HEALTH' => const Color(0xFF3B82F6),
  'TRAVEL' => const Color(0xFF8B5CF6),
  'SERVICES' => const Color(0xFF64748B),
  _ => const Color(0xFF9B5DE5),
};

List<Color> _gradientFromKey(String key) => switch (key) {
  'RESTAURANT' => const [Color(0xFF1A0535), Color(0xFF9B5DE5)],
  'CAFE' => const [Color(0xFF7C2D12), Color(0xFFF59E0B)],
  'FITNESS' => const [Color(0xFF052E16), Color(0xFF22C55E)],
  'BEAUTY' => const [Color(0xFF3B0764), Color(0xFFF15BB5)],
  'RETAIL' => const [Color(0xFF1E1B4B), Color(0xFF9B5DE5)],
  'GROCERY' => const [Color(0xFF0F2027), Color(0xFF00D4FF)],
  'ENTERTAINMENT' => const [Color(0xFF1A0A00), Color(0xFFFF6B35)],
  'HEALTH' => const [Color(0xFF0C1445), Color(0xFF3B82F6)],
  'TRAVEL' => const [Color(0xFF1A0A00), Color(0xFF8B5CF6)],
  'SERVICES' => const [Color(0xFF1A1A2E), Color(0xFF64748B)],
  _ => const [Color(0xFF1A0535), Color(0xFF9B5DE5)],
};

String _emojiFromKey(String key) => switch (key) {
  'RESTAURANT' => '🍽️',
  'CAFE' => '☕',
  'FITNESS' => '💪',
  'BEAUTY' => '✨',
  'RETAIL' => '👗',
  'GROCERY' => '🌿',
  'ENTERTAINMENT' => '🎬',
  'HEALTH' => '🏥',
  'TRAVEL' => '✈️',
  'SERVICES' => '🧰',
  _ => '🏷️',
};

IconData _iconFromKey(String key) => switch (key) {
  'RESTAURANT' => Icons.restaurant_rounded,
  'CAFE' => Icons.local_cafe_rounded,
  'FITNESS' => Icons.fitness_center_rounded,
  'BEAUTY' => Icons.spa_rounded,
  'RETAIL' => Icons.shopping_bag_rounded,
  'GROCERY' => Icons.local_grocery_store_rounded,
  'ENTERTAINMENT' => Icons.movie_rounded,
  'HEALTH' => Icons.health_and_safety_rounded,
  'TRAVEL' => Icons.flight_rounded,
  'SERVICES' => Icons.miscellaneous_services_rounded,
  _ => Icons.store_rounded,
};
