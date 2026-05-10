import 'package:flutter/material.dart';
import '../../data/models/customer_home_dto.dart';
import 'customer_ui_models.dart';

// ─── CustomerProfile ──────────────────────────────────────────────────────────
// Mirrors the customer profile fields expected by existing widgets.

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
    // The current /home payload does not include identity/contact fields yet,
    // so profile UI falls back until a dedicated profile endpoint is wired in.
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
// Runtime data source backed by API data.

class CustomerDataSource {
  const CustomerDataSource({
    required this.summary,
    required this.categories,
    required this.businesses,
    required this.coupons,
    required this.rewards,
    required this.transactions,
  });

  final CustomerProfile summary;
  final List<CustomerCategory> categories;
  final List<CustomerBusiness> businesses;
  final List<CustomerCoupon> coupons;
  final List<CustomerReward> rewards;
  final List<CustomerTransaction> transactions;

  // ── Computed accessors used by the customer UI ────────────────────────────

  List<CustomerBusiness> get businessesWithPoints =>
      businesses.where((b) => b.points > 0).toList();

  List<CustomerCoupon> get myCoupons =>
      coupons.where((c) => c.isOwned).toList();

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

  // ── Factories ─────────────────────────────────────────────────────────────

  factory CustomerDataSource.empty() {
    return CustomerDataSource(
      summary: CustomerProfile.empty(),
      categories: const [],
      businesses: const [],
      coupons: const [],
      rewards: const [],
      transactions: const [],
    );
  }

  factory CustomerDataSource.fromDto(CustomerHomeDto dto) {
    // Build businessId → categoryKey lookup for coupon/transaction mapping.
    final bizCategoryMap = <int, String>{
      for (final b in dto.businesses) b.id: b.categoryKey,
    };

    final businesses = dto.businesses.map(_mapBusiness).toList();

    final hasExplicitOwnership = dto.promotions.any(
      (promotion) => promotion.hasOwnershipSignal,
    );
    final mappedCoupons = dto.promotions
        .map((p) => _mapPromotion(p, bizCategoryMap))
        .toList();
    final normalizedCoupons = hasExplicitOwnership
        ? mappedCoupons
        : mappedCoupons
              .map(
                (coupon) => CustomerCoupon(
                  id: coupon.id,
                  businessId: coupon.businessId,
                  businessName: coupon.businessName,
                  title: coupon.title,
                  discountValue: coupon.discountValue,
                  discountDisplay: coupon.discountDisplay,
                  status: coupon.status,
                  expiresAt: coupon.expiresAt,
                  pointCost: coupon.pointCost,
                  gradientColors: coupon.gradientColors,
                  type: coupon.type,
                  isUsed: coupon.isUsed,
                  description: coupon.description,
                  termsAndConditions: coupon.termsAndConditions,
                  usageLimit: coupon.usageLimit,
                  usageCount: coupon.usageCount,
                  isHot: coupon.isHot,
                  multiplierLabel: coupon.multiplierLabel,
                  isOwned: true,
                ),
              )
              .toList();

    return CustomerDataSource(
      summary: CustomerProfile.fromSummaryDto(dto.summary),
      categories: dto.categories.map(_mapCategory).toList(),
      businesses: businesses,
      coupons: normalizedCoupons,
      rewards: businesses.map(_mapRewardFromBusiness).toList(),
      transactions: dto.transactions
          .map((t) => _mapTransaction(t, bizCategoryMap))
          .toList(),
    );
  }
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
  return CustomerBusiness(
    id: dto.id,
    name: dto.name,
    category: dto.categoryLabel,
    categoryId: dto.categoryId,
    gradientColors: _gradientFromKey(dto.categoryKey),
    points: dto.points,
    nextRewardPoints: dto.nextRewardPoints,
    distance: 'Unavailable',
    isOpen: dto.isOpen ?? false,
    rating: dto.rating ?? 0.0,
    logoEmoji: _emojiFromKey(dto.categoryKey),
    address: dto.address ?? '',
    phone: dto.phone ?? '',
    email: dto.email ?? '',
    openingHours: 'Unavailable',
    hasOffer: dto.hasOffer,
    offerLabel: dto.offerLabel,
    description: dto.description ?? '',
    hasLogo: dto.hasLogo,
  );
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

CustomerCoupon _mapPromotion(
  CustomerPromotionDto dto,
  Map<int, String> bizCategoryMap,
) {
  final categoryKey = bizCategoryMap[dto.businessId] ?? '';
  final expires =
      DateTime.tryParse(dto.expiresAt ?? '') ??
      DateTime.now().add(const Duration(days: 30));

  return CustomerCoupon(
    id: dto.id,
    businessId: dto.businessId,
    businessName: dto.businessName,
    title: dto.title,
    discountValue: 0,
    discountDisplay: dto.discountDisplay,
    status: dto.status.toLowerCase(),
    expiresAt: expires,
    pointCost: dto.pointCost,
    gradientColors: _gradientFromKey(categoryKey),
    type: dto.promotionType,
    isUsed: dto.isUsed,
    description: dto.description,
    termsAndConditions: dto.termsAndConditions ?? '',
    usageLimit: dto.usageLimit,
    usageCount: dto.usageCount,
    isHot: dto.isHot,
    isOwned: dto.isOwned,
  );
}

CustomerTransaction _mapTransaction(
  CustomerTransactionDto dto,
  Map<int, String> bizCategoryMap,
) {
  final categoryKey = bizCategoryMap[dto.businessId] ?? '';
  final date = DateTime.tryParse(dto.date) ?? DateTime.now();

  return CustomerTransaction(
    id: dto.id,
    businessId: dto.businessId,
    businessName: dto.businessName,
    type: dto.type,
    points: dto.points,
    date: date,
    description: dto.description,
    netAmount: dto.netAmount ?? 0.0,
    billAmount: dto.billAmount ?? 0.0,
    logoEmoji: _emojiFromKey(categoryKey),
    referenceId: dto.referenceId,
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
