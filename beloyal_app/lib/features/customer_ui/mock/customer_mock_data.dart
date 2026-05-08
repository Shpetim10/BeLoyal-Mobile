import 'package:flutter/material.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class MockCategory {
  const MockCategory({
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

class MockBusiness {
  const MockBusiness({
    required this.id,
    required this.name,
    required this.category,
    required this.categoryId,
    required this.gradientColors,
    required this.points,
    required this.nextRewardPoints,
    required this.distance,
    required this.isOpen,
    required this.rating,
    required this.logoEmoji,
    required this.address,
    required this.phone,
    required this.email,
    required this.openingHours,
    this.hasOffer = false,
    this.offerLabel,
    this.description = '',
  });
  final int id;
  final String name;
  final String category;
  final int categoryId;
  final List<Color> gradientColors;
  final int points;
  final int nextRewardPoints;
  final String distance;
  final bool isOpen;
  final double rating;
  final String logoEmoji;
  final String address;
  final String phone;
  final String email;
  final String openingHours;
  final bool hasOffer;
  final String? offerLabel;
  final String description;
}

class MockOffer {
  const MockOffer({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.title,
    required this.description,
    required this.gradientColors,
    required this.multiplier,
    required this.validUntil,
    required this.isHot,
  });
  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final String multiplier;
  final DateTime validUntil;
  final bool isHot;
}

class MockCoupon {
  const MockCoupon({
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
    required this.type, // FREE_PRODUCT | PERCENTAGE_DISCOUNT | FIXED_AMOUNT_DISCOUNT
    this.isUsed = false,
    this.description = '',
    this.termsAndConditions = '',
    this.usageLimit,
    this.usageCount = 0,
  });
  final int id;
  final int businessId;
  final String businessName;
  final String title;
  final double discountValue;
  final String discountDisplay;
  final String status; // active, used, expiring, expired
  final DateTime expiresAt;
  final int pointCost;
  final List<Color> gradientColors;
  final String type;
  final bool isUsed;
  final String description;
  final String termsAndConditions;
  final int? usageLimit;
  final int usageCount;
}

class MockReward {
  const MockReward({
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

class MockOrder {
  const MockOrder({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.type,
    required this.status,
    required this.date,
    required this.amount,
    required this.pointsEarned,
    required this.pointsRedeemed,
    required this.gradientColors,
    required this.logoEmoji,
    this.description = '',
    this.referenceId,
  });
  final int id;
  final int businessId;
  final String businessName;
  final String type; // order, visit, reservation, booking, invoice
  final String status; // completed, pending, canceled, refunded, visited, no_show
  final DateTime date;
  final double amount;
  final int pointsEarned;
  final int pointsRedeemed;
  final List<Color> gradientColors;
  final String logoEmoji;
  final String description;
  final String? referenceId;
}

class MockTransaction {
  const MockTransaction({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.type, // EARN | REDEEM | ADJUSTMENT | EXPIRED | REFUND
    required this.points,
    required this.date,
    required this.description,
    required this.netAmount,
    required this.billAmount,
    required this.logoEmoji,
    this.referenceId,
    this.discountAmount,
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
}

class MockMenuItem {
  const MockMenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.menuCategory,
    required this.emoji,
    this.pointsLabel = '',
    this.isPopular = false,
  });
  final int id;
  final String name;
  final String description;
  final double price;
  final String menuCategory;
  final String emoji;
  final String pointsLabel;
  final bool isPopular;
}

// ─── Seeded Data ──────────────────────────────────────────────────────────────

abstract final class CustomerMockData {
  static const customer = _MockCustomer(
    firstName: 'Alexandra',
    lastName: 'Berisha',
    email: 'alex.berisha@email.com',
    phone: '+355 69 123 4567',
    lifetimePoints: 14820,
    currentPoints: 3240,
    spentPoints: 11580,
    businessesVisited: 18,
    activeCoupons: 4,
    activeRewards: 7,
    memberSince: 'March 2023',
    memberCode: 'ALEX-8472',
    roles: ['Customer', 'Business Admin'],
  );

  static const categories = <MockCategory>[
    MockCategory(id: 1, name: 'Restaurants', icon: Icons.restaurant_rounded, color: Color(0xFFEF4444), businessCount: 24, hasBonus: true),
    MockCategory(id: 2, name: 'Cafés', icon: Icons.local_cafe_rounded, color: Color(0xFFF59E0B), businessCount: 18, hasBonus: false),
    MockCategory(id: 3, name: 'Fitness', icon: Icons.fitness_center_rounded, color: Color(0xFF22C55E), businessCount: 9, hasBonus: true),
    MockCategory(id: 4, name: 'Beauty', icon: Icons.spa_rounded, color: Color(0xFFF15BB5), businessCount: 15, hasBonus: false),
    MockCategory(id: 5, name: 'Retail', icon: Icons.shopping_bag_rounded, color: Color(0xFF9B5DE5), businessCount: 31, hasBonus: true),
    MockCategory(id: 6, name: 'Grocery', icon: Icons.local_grocery_store_rounded, color: Color(0xFF00D4FF), businessCount: 12, hasBonus: false),
    MockCategory(id: 7, name: 'Entertainment', icon: Icons.movie_rounded, color: Color(0xFFFF6B35), businessCount: 7, hasBonus: false),
    MockCategory(id: 8, name: 'Health', icon: Icons.health_and_safety_rounded, color: Color(0xFF3B82F6), businessCount: 11, hasBonus: false),
    MockCategory(id: 9, name: 'Travel', icon: Icons.flight_rounded, color: Color(0xFF8B5CF6), businessCount: 5, hasBonus: false),
    MockCategory(id: 10, name: 'Services', icon: Icons.miscellaneous_services_rounded, color: Color(0xFF64748B), businessCount: 20, hasBonus: false),
  ];

  static final businesses = <MockBusiness>[
    MockBusiness(
      id: 1, name: 'Noir Bistro', category: 'Restaurants', categoryId: 1,
      gradientColors: [Color(0xFF1A0535), Color(0xFF9B5DE5)],
      points: 310, nextRewardPoints: 500,
      distance: '0.3 km', isOpen: true, rating: 4.8,
      logoEmoji: '🍽️',
      address: 'Rruga Elbasanit 12, Tirana',
      phone: '+355 4 222 3344',
      email: 'info@nourbistro.al',
      openingHours: 'Mon–Fri 11:00–23:00 · Sat–Sun 12:00–00:00',
      hasOffer: true, offerLabel: '2× pts today',
      description: 'Fine dining with a modern twist. Earn double points on weekend dinners.',
    ),
    MockBusiness(
      id: 2, name: 'Bravo Coffee', category: 'Cafés', categoryId: 2,
      gradientColors: [Color(0xFF7C2D12), Color(0xFFF59E0B)],
      points: 820, nextRewardPoints: 1000,
      distance: '0.8 km', isOpen: true, rating: 4.9,
      logoEmoji: '☕',
      address: 'Blloku, Rruga Pjetër Bogdani 8, Tirana',
      phone: '+355 4 225 6677',
      email: 'hello@bravocoffee.al',
      openingHours: 'Daily 07:00–22:00',
      description: 'Specialty coffee roasters with 12 house blends and a loyalty stamp card.',
    ),
    MockBusiness(
      id: 3, name: 'FitZone Pro', category: 'Fitness', categoryId: 3,
      gradientColors: [Color(0xFF052E16), Color(0xFF22C55E)],
      points: 150, nextRewardPoints: 300,
      distance: '1.2 km', isOpen: true, rating: 4.6,
      logoEmoji: '💪',
      address: 'Rruga Myslym Shyri 44, Tirana',
      phone: '+355 4 230 1122',
      email: 'members@fitzonepro.al',
      openingHours: 'Mon–Fri 06:00–22:00 · Sat 08:00–20:00 · Sun 09:00–18:00',
      hasOffer: true, offerLabel: 'Free class',
      description: 'Premium gym with group classes, personal trainers, and recovery lounge.',
    ),
    MockBusiness(
      id: 4, name: 'Glow Studio', category: 'Beauty', categoryId: 4,
      gradientColors: [Color(0xFF3B0764), Color(0xFFF15BB5)],
      points: 540, nextRewardPoints: 750,
      distance: '0.5 km', isOpen: false, rating: 4.7,
      logoEmoji: '✨',
      address: 'Rruga Ismail Qemali 3, Tirana',
      phone: '+355 4 222 8899',
      email: 'book@glowstudio.al',
      openingHours: 'Tue–Sat 09:00–19:00 · Sun 10:00–17:00 · Mon Closed',
      description: 'Award-winning salon offering hair, nails, and skin treatments.',
    ),
    MockBusiness(
      id: 5, name: 'Urban Thread', category: 'Retail', categoryId: 5,
      gradientColors: [Color(0xFF1E1B4B), Color(0xFF9B5DE5)],
      points: 200, nextRewardPoints: 500,
      distance: '2.1 km', isOpen: true, rating: 4.4,
      logoEmoji: '👗',
      address: 'Sheshi Italia, QTU Mall, Tirana',
      phone: '+355 4 240 5566',
      email: 'shop@urbanthread.al',
      openingHours: 'Daily 10:00–21:00',
      hasOffer: true, offerLabel: '15% off',
      description: 'Contemporary fashion with curated local and international designers.',
    ),
    MockBusiness(
      id: 6, name: 'Verde Market', category: 'Grocery', categoryId: 6,
      gradientColors: [Color(0xFF0F2027), Color(0xFF00D4FF)],
      points: 660, nextRewardPoints: 1000,
      distance: '0.4 km', isOpen: true, rating: 4.5,
      logoEmoji: '🌿',
      address: 'Rruga Kavajës 88, Tirana',
      phone: '+355 4 235 4455',
      email: 'orders@verdemarket.al',
      openingHours: 'Mon–Sat 08:00–21:00 · Sun 09:00–18:00',
      description: 'Organic and locally sourced produce, dairy, and pantry staples.',
    ),
    MockBusiness(
      id: 7, name: 'Cinema Luxe', category: 'Entertainment', categoryId: 7,
      gradientColors: [Color(0xFF1A0A00), Color(0xFFFF6B35)],
      points: 90, nextRewardPoints: 200,
      distance: '3.0 km', isOpen: true, rating: 4.3,
      logoEmoji: '🎬',
      address: 'Rruga Dëshmorëve, Arena Center, Tirana',
      phone: '+355 4 260 7788',
      email: 'tickets@cinemaluxe.al',
      openingHours: 'Daily 11:00–00:00',
      description: 'Premium cinema with VIP seating, 4K laser projection, and Dolby Atmos.',
    ),
    MockBusiness(
      id: 8, name: 'MedCare Clinic', category: 'Health', categoryId: 8,
      gradientColors: [Color(0xFF0C1445), Color(0xFF3B82F6)],
      points: 420, nextRewardPoints: 600,
      distance: '1.5 km', isOpen: true, rating: 4.9,
      logoEmoji: '🏥',
      address: 'Rruga Sulejman Delvina 22, Tirana',
      phone: '+355 4 245 9900',
      email: 'care@medcareclinic.al',
      openingHours: 'Mon–Fri 08:00–18:00 · Sat 09:00–14:00 · Sun Closed',
      description: 'Comprehensive healthcare with specialist consultations and diagnostics.',
    ),
  ];

  static final hotOffers = <MockOffer>[
    MockOffer(
      id: 1, businessId: 1, businessName: 'Noir Bistro', title: 'Double Points Weekend',
      description: 'Earn 2× points on all orders this weekend. Valid Sat–Sun.',
      gradientColors: [Color(0xFF9B5DE5), Color(0xFFF15BB5)],
      multiplier: '2×', validUntil: DateTime.now().add(const Duration(days: 2)), isHot: true,
    ),
    MockOffer(
      id: 2, businessId: 2, businessName: 'Bravo Coffee', title: 'Morning Boost',
      description: 'Get 50 bonus points on every coffee before 10am.',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      multiplier: '+50 pts', validUntil: DateTime.now().add(const Duration(days: 7)), isHot: true,
    ),
    MockOffer(
      id: 3, businessId: 3, businessName: 'FitZone Pro', title: 'Bring a Friend',
      description: 'Bring a friend and both earn 200 bonus points.',
      gradientColors: [Color(0xFF22C55E), Color(0xFF00D4FF)],
      multiplier: '+200 pts', validUntil: DateTime.now().add(const Duration(days: 14)), isHot: false,
    ),
    MockOffer(
      id: 4, businessId: 5, businessName: 'Urban Thread', title: 'Flash Sale Bonus',
      description: 'Shop today and earn 3× loyalty points. Limited time.',
      gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      multiplier: '3×', validUntil: DateTime.now().add(const Duration(hours: 8)), isHot: true,
    ),
    MockOffer(
      id: 5, businessId: 6, businessName: 'Verde Market', title: 'Organic Week',
      description: 'Extra 100 points on all organic products this week.',
      gradientColors: [Color(0xFF059669), Color(0xFF00D4FF)],
      multiplier: '+100 pts', validUntil: DateTime.now().add(const Duration(days: 5)), isHot: false,
    ),
    MockOffer(
      id: 6, businessId: 4, businessName: 'Glow Studio', title: 'Refer & Earn',
      description: 'Refer a friend to Glow Studio and earn 300 points when they book.',
      gradientColors: [Color(0xFFDB2777), Color(0xFFF15BB5)],
      multiplier: '+300 pts', validUntil: DateTime.now().add(const Duration(days: 30)), isHot: false,
    ),
  ];

  static final coupons = <MockCoupon>[
    // Active coupons
    MockCoupon(
      id: 1, businessId: 2, businessName: 'Bravo Coffee', title: 'Free Espresso',
      discountValue: 0, discountDisplay: 'Free Item', status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 14)),
      pointCost: 500, gradientColors: [Color(0xFF7C2D12), Color(0xFFF59E0B)],
      type: 'FREE_PRODUCT',
      description: 'Redeem for any single espresso of your choice.',
      termsAndConditions: 'Valid for one espresso per visit. Cannot be combined with other offers.',
      usageLimit: 1, usageCount: 0,
    ),
    MockCoupon(
      id: 2, businessId: 1, businessName: 'Noir Bistro', title: '20% Off Dinner',
      discountValue: 20, discountDisplay: '20% OFF', status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 21)),
      pointCost: 800, gradientColors: [Color(0xFF1A0535), Color(0xFF9B5DE5)],
      type: 'PERCENTAGE_DISCOUNT',
      description: '20% discount on your total dinner bill. Minimum spend L 2,000.',
      termsAndConditions: 'Valid Mon–Thu evenings only. Not valid on public holidays.',
      usageLimit: 1, usageCount: 0,
    ),
    MockCoupon(
      id: 3, businessId: 5, businessName: 'Urban Thread', title: 'L 10 Discount',
      discountValue: 10, discountDisplay: 'L 10 OFF', status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      pointCost: 400, gradientColors: [Color(0xFF1E1B4B), Color(0xFF6366F1)],
      type: 'FIXED_AMOUNT_DISCOUNT',
      description: 'L 10 off any full-price item. No minimum spend.',
      termsAndConditions: 'Cannot be combined with sale items or other discounts.',
      usageLimit: 2, usageCount: 0,
    ),
    MockCoupon(
      id: 4, businessId: 8, businessName: 'MedCare Clinic', title: '15% Health Check',
      discountValue: 15, discountDisplay: '15% OFF', status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 45)),
      pointCost: 600, gradientColors: [Color(0xFF0C1445), Color(0xFF3B82F6)],
      type: 'PERCENTAGE_DISCOUNT',
      description: '15% off any diagnostic package or specialist consultation.',
      termsAndConditions: 'Subject to appointment availability. Not valid for emergency services.',
      usageLimit: 1, usageCount: 0,
    ),
    // Expiring soon
    MockCoupon(
      id: 5, businessId: 3, businessName: 'FitZone Pro', title: 'Free Class Pass',
      discountValue: 0, discountDisplay: 'Free Class', status: 'expiring',
      expiresAt: DateTime.now().add(const Duration(days: 2)),
      pointCost: 600, gradientColors: [Color(0xFF052E16), Color(0xFF22C55E)],
      type: 'FREE_PRODUCT',
      description: 'One free group class of your choice — yoga, HIIT, or cycling.',
      termsAndConditions: 'Must book 24h in advance. Subject to availability.',
      usageLimit: 1, usageCount: 0,
    ),
    MockCoupon(
      id: 6, businessId: 4, businessName: 'Glow Studio', title: 'Hair Treatment 30% Off',
      discountValue: 30, discountDisplay: '30% OFF', status: 'expiring',
      expiresAt: DateTime.now().add(const Duration(days: 1)),
      pointCost: 1000, gradientColors: [Color(0xFF3B0764), Color(0xFFF15BB5)],
      type: 'PERCENTAGE_DISCOUNT',
      description: '30% off any hair treatment or coloring service.',
      termsAndConditions: 'Valid for single visit. Cannot be combined with membership discounts.',
      usageLimit: 1, usageCount: 0,
    ),
    // Used coupons
    MockCoupon(
      id: 7, businessId: 6, businessName: 'Verde Market', title: 'Organic Bundle',
      discountValue: 15, discountDisplay: 'L 15 OFF', status: 'used', isUsed: true,
      expiresAt: DateTime.now().subtract(const Duration(days: 3)),
      pointCost: 700, gradientColors: [Color(0xFF0F2027), Color(0xFF00D4FF)],
      type: 'FIXED_AMOUNT_DISCOUNT',
      description: 'L 15 off your organic basket purchase.',
      usageLimit: 1, usageCount: 1,
    ),
    MockCoupon(
      id: 8, businessId: 7, businessName: 'Cinema Luxe', title: '2-for-1 Tickets',
      discountValue: 50, discountDisplay: '2 for 1', status: 'used', isUsed: true,
      expiresAt: DateTime.now().subtract(const Duration(days: 7)),
      pointCost: 900, gradientColors: [Color(0xFF1A0A00), Color(0xFFFF6B35)],
      type: 'PERCENTAGE_DISCOUNT',
      description: 'Buy one ticket, get one free for any standard screening.',
      usageLimit: 1, usageCount: 1,
    ),
    MockCoupon(
      id: 9, businessId: 8, businessName: 'MedCare Clinic', title: 'Free Consultation',
      discountValue: 0, discountDisplay: 'Free Visit', status: 'used', isUsed: true,
      expiresAt: DateTime.now().subtract(const Duration(days: 14)),
      pointCost: 1200, gradientColors: [Color(0xFF0C1445), Color(0xFF3B82F6)],
      type: 'FREE_PRODUCT',
      description: 'One free general practice consultation.',
      usageLimit: 1, usageCount: 1,
    ),
    // Expired
    MockCoupon(
      id: 10, businessId: 2, businessName: 'Bravo Coffee', title: 'Loyalty Bundle',
      discountValue: 25, discountDisplay: '25% OFF', status: 'expired',
      expiresAt: DateTime.now().subtract(const Duration(days: 5)),
      pointCost: 600, gradientColors: [Color(0xFF374151), Color(0xFF6B7280)],
      type: 'PERCENTAGE_DISCOUNT',
      description: '25% off your entire order.',
      usageLimit: 1, usageCount: 0,
    ),
    MockCoupon(
      id: 11, businessId: 1, businessName: 'Noir Bistro', title: 'Weekend Brunch',
      discountValue: 20, discountDisplay: 'L 20 OFF', status: 'expired',
      expiresAt: DateTime.now().subtract(const Duration(days: 10)),
      pointCost: 850, gradientColors: [Color(0xFF374151), Color(0xFF6B7280)],
      type: 'FIXED_AMOUNT_DISCOUNT',
      description: 'L 20 off your weekend brunch bill. Min spend L 3,000.',
      usageLimit: 1, usageCount: 0,
    ),
    // Premium active coupons (high point cost)
    MockCoupon(
      id: 12, businessId: 5, businessName: 'Urban Thread', title: 'VIP Member Discount',
      discountValue: 50, discountDisplay: '50% OFF', status: 'active',
      expiresAt: DateTime.now().add(const Duration(days: 60)),
      pointCost: 2000, gradientColors: [Color(0xFF1E1B4B), Color(0xFF9B5DE5)],
      type: 'PERCENTAGE_DISCOUNT',
      description: '50% off any full-price item. Our most exclusive coupon.',
      termsAndConditions: 'One use per customer. Cannot be combined with any other offer.',
      usageLimit: 1, usageCount: 0,
    ),
  ];

  static final rewards = <MockReward>[
    MockReward(
      id: 1, businessId: 2, businessName: 'Bravo Coffee', title: 'Free Cappuccino',
      description: 'Redeem for any hot or cold cappuccino of your choice.',
      pointCost: 500, currentPoints: 820,
      gradientColors: [Color(0xFF7C2D12), Color(0xFFF59E0B)],
      category: 'Cafés', logoEmoji: '☕',
    ),
    MockReward(
      id: 2, businessId: 2, businessName: 'Bravo Coffee', title: 'Monthly Brew Pass',
      description: 'Unlimited drip coffee for 30 days.',
      pointCost: 1800, currentPoints: 820,
      gradientColors: [Color(0xFF451A03), Color(0xFFF59E0B)],
      category: 'Cafés', logoEmoji: '☕',
    ),
    MockReward(
      id: 3, businessId: 1, businessName: 'Noir Bistro', title: 'Complimentary Dessert',
      description: 'One dessert of your choice on your next visit.',
      pointCost: 400, currentPoints: 310,
      gradientColors: [Color(0xFF1A0535), Color(0xFF9B5DE5)],
      category: 'Restaurants', logoEmoji: '🍽️',
    ),
    MockReward(
      id: 4, businessId: 1, businessName: 'Noir Bistro', title: "Chef's Table Experience",
      description: 'Exclusive 7-course tasting menu for 2 people.',
      pointCost: 5000, currentPoints: 310,
      gradientColors: [Color(0xFF1A0535), Color(0xFFF15BB5)],
      category: 'Restaurants', logoEmoji: '🍽️',
    ),
    MockReward(
      id: 5, businessId: 3, businessName: 'FitZone Pro', title: 'Personal Training Session',
      description: '60-minute 1-on-1 session with a certified trainer.',
      pointCost: 800, currentPoints: 150,
      gradientColors: [Color(0xFF052E16), Color(0xFF22C55E)],
      category: 'Fitness', logoEmoji: '💪',
    ),
    MockReward(
      id: 6, businessId: 4, businessName: 'Glow Studio', title: 'Relaxation Massage',
      description: '45-minute full body relaxation massage.',
      pointCost: 1200, currentPoints: 540,
      gradientColors: [Color(0xFF3B0764), Color(0xFFF15BB5)],
      category: 'Beauty', logoEmoji: '✨',
    ),
    MockReward(
      id: 7, businessId: 6, businessName: 'Verde Market', title: 'Organic Basket',
      description: 'Weekly organic produce basket delivered to your door.',
      pointCost: 950, currentPoints: 660,
      gradientColors: [Color(0xFF0F2027), Color(0xFF00D4FF)],
      category: 'Grocery', logoEmoji: '🌿',
    ),
    MockReward(
      id: 8, businessId: 5, businessName: 'Urban Thread', title: 'Styling Consultation',
      description: 'Personal styling session with our expert stylists.',
      pointCost: 600, currentPoints: 200,
      gradientColors: [Color(0xFF1E1B4B), Color(0xFF6366F1)],
      category: 'Retail', logoEmoji: '👗',
    ),
    MockReward(
      id: 9, businessId: 7, businessName: 'Cinema Luxe', title: 'VIP Screening Night',
      description: 'Private VIP lounge screening for you and a guest.',
      pointCost: 2500, currentPoints: 90,
      gradientColors: [Color(0xFF1A0A00), Color(0xFFFF6B35)],
      category: 'Entertainment', logoEmoji: '🎬',
    ),
    MockReward(
      id: 10, businessId: 8, businessName: 'MedCare Clinic', title: 'Health Checkup',
      description: 'Comprehensive annual health screening package.',
      pointCost: 1500, currentPoints: 420,
      gradientColors: [Color(0xFF0C1445), Color(0xFF3B82F6)],
      category: 'Health', logoEmoji: '🏥',
    ),
  ];

  static final orders = <MockOrder>[
    MockOrder(
      id: 1, businessId: 2, businessName: 'Bravo Coffee', type: 'order', status: 'completed',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      amount: 4.50, pointsEarned: 45, pointsRedeemed: 0,
      gradientColors: [Color(0xFF7C2D12), Color(0xFFF59E0B)], logoEmoji: '☕',
      description: 'Flat White + Croissant', referenceId: 'ORD-2024-0891',
    ),
    MockOrder(
      id: 2, businessId: 1, businessName: 'Noir Bistro', type: 'reservation', status: 'pending',
      date: DateTime.now().add(const Duration(days: 2)),
      amount: 0, pointsEarned: 0, pointsRedeemed: 0,
      gradientColors: [Color(0xFF1A0535), Color(0xFF9B5DE5)], logoEmoji: '🍽️',
      description: 'Table for 2 – 8:00 PM', referenceId: 'RES-2024-0245',
    ),
    MockOrder(
      id: 3, businessId: 3, businessName: 'FitZone Pro', type: 'visit', status: 'visited',
      date: DateTime.now().subtract(const Duration(days: 1)),
      amount: 12.00, pointsEarned: 120, pointsRedeemed: 0,
      gradientColors: [Color(0xFF052E16), Color(0xFF22C55E)], logoEmoji: '💪',
      description: 'HIIT Class – Morning session', referenceId: 'VIS-2024-1102',
    ),
    MockOrder(
      id: 4, businessId: 4, businessName: 'Glow Studio', type: 'booking', status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 3)),
      amount: 45.00, pointsEarned: 450, pointsRedeemed: 200,
      gradientColors: [Color(0xFF3B0764), Color(0xFFF15BB5)], logoEmoji: '✨',
      description: 'Hair Color + Treatment', referenceId: 'BKG-2024-0567',
    ),
    MockOrder(
      id: 5, businessId: 6, businessName: 'Verde Market', type: 'order', status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 4)),
      amount: 32.80, pointsEarned: 328, pointsRedeemed: 0,
      gradientColors: [Color(0xFF0F2027), Color(0xFF00D4FF)], logoEmoji: '🌿',
      description: 'Weekly grocery + organic basket', referenceId: 'ORD-2024-0756',
    ),
    MockOrder(
      id: 6, businessId: 7, businessName: 'Cinema Luxe', type: 'booking', status: 'canceled',
      date: DateTime.now().subtract(const Duration(days: 6)),
      amount: 0, pointsEarned: 0, pointsRedeemed: 0,
      gradientColors: [Color(0xFF1A0A00), Color(0xFFFF6B35)], logoEmoji: '🎬',
      description: 'VIP Screening – Fri Night', referenceId: 'BKG-2024-0421',
    ),
    MockOrder(
      id: 7, businessId: 5, businessName: 'Urban Thread', type: 'invoice', status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 8)),
      amount: 128.00, pointsEarned: 640, pointsRedeemed: 100,
      gradientColors: [Color(0xFF1E1B4B), Color(0xFF6366F1)], logoEmoji: '👗',
      description: 'Summer collection haul – 4 items', referenceId: 'INV-2024-0312',
    ),
    MockOrder(
      id: 8, businessId: 8, businessName: 'MedCare Clinic', type: 'visit', status: 'visited',
      date: DateTime.now().subtract(const Duration(days: 12)),
      amount: 55.00, pointsEarned: 550, pointsRedeemed: 0,
      gradientColors: [Color(0xFF0C1445), Color(0xFF3B82F6)], logoEmoji: '🏥',
      description: 'Annual checkup + blood panel', referenceId: 'VIS-2024-0198',
    ),
    MockOrder(
      id: 9, businessId: 2, businessName: 'Bravo Coffee', type: 'order', status: 'refunded',
      date: DateTime.now().subtract(const Duration(days: 15)),
      amount: 6.50, pointsEarned: 0, pointsRedeemed: 0,
      gradientColors: [Color(0xFF374151), Color(0xFF6B7280)], logoEmoji: '☕',
      description: 'Cold brew – refunded (wrong order)', referenceId: 'ORD-2024-0623',
    ),
    MockOrder(
      id: 10, businessId: 3, businessName: 'FitZone Pro', type: 'booking', status: 'no_show',
      date: DateTime.now().subtract(const Duration(days: 18)),
      amount: 0, pointsEarned: 0, pointsRedeemed: 0,
      gradientColors: [Color(0xFF374151), Color(0xFF6B7280)], logoEmoji: '💪',
      description: 'Yoga session – no show', referenceId: 'BKG-2024-0389',
    ),
    MockOrder(
      id: 11, businessId: 1, businessName: 'Noir Bistro', type: 'order', status: 'completed',
      date: DateTime.now().subtract(const Duration(days: 20)),
      amount: 89.00, pointsEarned: 890, pointsRedeemed: 500,
      gradientColors: [Color(0xFF1A0535), Color(0xFF9B5DE5)], logoEmoji: '🍽️',
      description: 'Dinner for 2 – anniversary', referenceId: 'ORD-2024-0541',
    ),
    MockOrder(
      id: 12, businessId: 4, businessName: 'Glow Studio', type: 'reservation', status: 'pending',
      date: DateTime.now().add(const Duration(days: 5)),
      amount: 0, pointsEarned: 0, pointsRedeemed: 0,
      gradientColors: [Color(0xFF3B0764), Color(0xFFF15BB5)], logoEmoji: '✨',
      description: 'Nail appointment – gel manicure', referenceId: 'RES-2024-0289',
    ),
  ];

  static final transactions = <MockTransaction>[
    MockTransaction(id: 1, businessId: 2, businessName: 'Bravo Coffee', type: 'EARN', points: 45, date: DateTime.now().subtract(const Duration(hours: 3)), description: 'Flat White + Croissant', netAmount: 4.50, billAmount: 4.50, logoEmoji: '☕', referenceId: 'ORD-2024-0891'),
    MockTransaction(id: 2, businessId: 3, businessName: 'FitZone Pro', type: 'EARN', points: 120, date: DateTime.now().subtract(const Duration(days: 1)), description: 'HIIT Class visit', netAmount: 12.00, billAmount: 12.00, logoEmoji: '💪', referenceId: 'VIS-2024-1102'),
    MockTransaction(id: 3, businessId: 4, businessName: 'Glow Studio', type: 'EARN', points: 450, date: DateTime.now().subtract(const Duration(days: 3)), description: 'Hair Color + Treatment', netAmount: 45.00, billAmount: 45.00, logoEmoji: '✨', referenceId: 'BKG-2024-0567'),
    MockTransaction(id: 4, businessId: 4, businessName: 'Glow Studio', type: 'REDEEM', points: -200, date: DateTime.now().subtract(const Duration(days: 3)), description: 'Points redeemed on booking', netAmount: 0, billAmount: 0, logoEmoji: '✨', referenceId: 'BKG-2024-0567'),
    MockTransaction(id: 5, businessId: 6, businessName: 'Verde Market', type: 'EARN', points: 328, date: DateTime.now().subtract(const Duration(days: 4)), description: 'Weekly grocery shop', netAmount: 32.80, billAmount: 32.80, logoEmoji: '🌿', referenceId: 'ORD-2024-0756'),
    MockTransaction(id: 6, businessId: 5, businessName: 'Urban Thread', type: 'EARN', points: 640, date: DateTime.now().subtract(const Duration(days: 8)), description: 'Summer collection – 4 items', netAmount: 128.00, billAmount: 128.00, logoEmoji: '👗', referenceId: 'INV-2024-0312'),
    MockTransaction(id: 7, businessId: 5, businessName: 'Urban Thread', type: 'REDEEM', points: -100, date: DateTime.now().subtract(const Duration(days: 8)), description: 'Coupon: L 10 discount applied', netAmount: 0, billAmount: 0, logoEmoji: '👗', referenceId: 'INV-2024-0312'),
    MockTransaction(id: 8, businessId: 8, businessName: 'MedCare Clinic', type: 'EARN', points: 550, date: DateTime.now().subtract(const Duration(days: 12)), description: 'Annual checkup', netAmount: 55.00, billAmount: 55.00, logoEmoji: '🏥', referenceId: 'VIS-2024-0198'),
    MockTransaction(id: 9, businessId: 2, businessName: 'Bravo Coffee', type: 'REFUND', points: 65, date: DateTime.now().subtract(const Duration(days: 15)), description: 'Order refund – wrong item', netAmount: 6.50, billAmount: 6.50, logoEmoji: '☕', referenceId: 'ORD-2024-0623'),
    MockTransaction(id: 10, businessId: 1, businessName: 'Noir Bistro', type: 'EARN', points: 890, date: DateTime.now().subtract(const Duration(days: 20)), description: 'Anniversary dinner', netAmount: 89.00, billAmount: 89.00, logoEmoji: '🍽️', referenceId: 'ORD-2024-0541'),
    MockTransaction(id: 11, businessId: 1, businessName: 'Noir Bistro', type: 'REDEEM', points: -500, date: DateTime.now().subtract(const Duration(days: 20)), description: 'Reward coupon redeemed', netAmount: 0, billAmount: 0, logoEmoji: '🍽️', referenceId: 'ORD-2024-0541'),
    MockTransaction(id: 12, businessId: 2, businessName: 'Bravo Coffee', type: 'EARN', points: 80, date: DateTime.now().subtract(const Duration(days: 25)), description: 'Lunch break coffees ×2', netAmount: 8.00, billAmount: 8.00, logoEmoji: '☕'),
    MockTransaction(id: 13, businessId: 3, businessName: 'FitZone Pro', type: 'EARN', points: 120, date: DateTime.now().subtract(const Duration(days: 28)), description: 'Group yoga session', netAmount: 12.00, billAmount: 12.00, logoEmoji: '💪'),
    MockTransaction(id: 14, businessId: 6, businessName: 'Verde Market', type: 'EXPIRED', points: -150, date: DateTime.now().subtract(const Duration(days: 32)), description: 'Points expired (180-day rule)', netAmount: 0, billAmount: 0, logoEmoji: '🌿'),
    MockTransaction(id: 15, businessId: 7, businessName: 'Cinema Luxe', type: 'EARN', points: 90, date: DateTime.now().subtract(const Duration(days: 35)), description: 'Movie tickets × 2', netAmount: 18.00, billAmount: 18.00, logoEmoji: '🎬'),
    MockTransaction(id: 16, businessId: 4, businessName: 'Glow Studio', type: 'EARN', points: 250, date: DateTime.now().subtract(const Duration(days: 40)), description: 'Mani + pedi session', netAmount: 25.00, billAmount: 25.00, logoEmoji: '✨'),
    MockTransaction(id: 17, businessId: 1, businessName: 'Noir Bistro', type: 'EARN', points: 340, date: DateTime.now().subtract(const Duration(days: 45)), description: 'Business lunch – 4 guests', netAmount: 68.00, billAmount: 68.00, logoEmoji: '🍽️'),
    MockTransaction(id: 18, businessId: 5, businessName: 'Urban Thread', type: 'ADJUSTMENT', points: 100, date: DateTime.now().subtract(const Duration(days: 50)), description: 'Manual adjustment – goodwill', netAmount: 0, billAmount: 0, logoEmoji: '👗'),
    MockTransaction(id: 19, businessId: 2, businessName: 'Bravo Coffee', type: 'EARN', points: 55, date: DateTime.now().subtract(const Duration(days: 55)), description: 'Morning brew – monthly pass', netAmount: 5.50, billAmount: 5.50, logoEmoji: '☕'),
    MockTransaction(id: 20, businessId: 8, businessName: 'MedCare Clinic', type: 'EARN', points: 300, date: DateTime.now().subtract(const Duration(days: 60)), description: 'Dental checkup', netAmount: 30.00, billAmount: 30.00, logoEmoji: '🏥'),
    MockTransaction(id: 21, businessId: 1, businessName: 'Noir Bistro', type: 'COUPON_PURCHASE', points: -150, date: DateTime.now().subtract(const Duration(hours: 6)), description: 'Bought coupon: 15% off next visit', netAmount: 0, billAmount: 0, logoEmoji: '🍽️', referenceId: 'CPN-2024-0041'),
    MockTransaction(id: 22, businessId: 2, businessName: 'Bravo Coffee', type: 'COUPON_PURCHASE', points: -80, date: DateTime.now().subtract(const Duration(days: 6)), description: 'Bought coupon: Free large coffee', netAmount: 0, billAmount: 0, logoEmoji: '☕', referenceId: 'CPN-2024-0035'),
    MockTransaction(id: 23, businessId: 5, businessName: 'Urban Thread', type: 'COUPON_PURCHASE', points: -200, date: DateTime.now().subtract(const Duration(days: 14)), description: 'Bought coupon: L 20 off on apparel', netAmount: 0, billAmount: 0, logoEmoji: '👗', referenceId: 'CPN-2024-0028'),
  ];

  static final menuItemsByBusinessId = <int, List<MockMenuItem>>{
    1: [ // Noir Bistro
      const MockMenuItem(id: 1, name: 'Truffle Arancini', description: 'Crispy rice balls with black truffle and mozzarella', price: 1200, menuCategory: 'Starters', emoji: '🫘', pointsLabel: '+12 pts', isPopular: true),
      const MockMenuItem(id: 2, name: 'Burrata Salad', description: 'Fresh burrata with heirloom tomatoes and basil oil', price: 1100, menuCategory: 'Starters', emoji: '🥗', pointsLabel: '+11 pts'),
      const MockMenuItem(id: 3, name: 'Wagyu Ribeye', description: '250g Wagyu ribeye, truffle butter, seasonal vegetables', price: 4800, menuCategory: 'Mains', emoji: '🥩', pointsLabel: '+48 pts', isPopular: true),
      const MockMenuItem(id: 4, name: 'Pan-Seared Duck', description: 'Confit duck leg, cherry jus, dauphinoise potato', price: 3200, menuCategory: 'Mains', emoji: '🍖', pointsLabel: '+32 pts'),
      const MockMenuItem(id: 5, name: 'Lobster Ravioli', description: 'Hand-made pasta, bisque cream sauce, micro herbs', price: 3600, menuCategory: 'Mains', emoji: '🦞', pointsLabel: '+36 pts'),
      const MockMenuItem(id: 6, name: 'Chocolate Fondant', description: 'Warm chocolate fondant, vanilla bean ice cream', price: 900, menuCategory: 'Desserts', emoji: '🍫', pointsLabel: '+9 pts', isPopular: true),
      const MockMenuItem(id: 7, name: 'Crème Brûlée', description: 'Classic vanilla crème brûlée with caramelised sugar', price: 800, menuCategory: 'Desserts', emoji: '🍮', pointsLabel: '+8 pts'),
    ],
    2: [ // Bravo Coffee
      const MockMenuItem(id: 8, name: 'Espresso', description: 'Double shot of our signature house blend', price: 150, menuCategory: 'Coffee', emoji: '☕', pointsLabel: '+2 pts', isPopular: true),
      const MockMenuItem(id: 9, name: 'Flat White', description: 'Velvety microfoam over a double ristretto', price: 280, menuCategory: 'Coffee', emoji: '🥛', pointsLabel: '+3 pts', isPopular: true),
      const MockMenuItem(id: 10, name: 'Cold Brew', description: '24-hour cold brew, served over ice', price: 350, menuCategory: 'Coffee', emoji: '🧊', pointsLabel: '+4 pts'),
      const MockMenuItem(id: 11, name: 'Chai Latte', description: 'Spiced masala chai with steamed oat milk', price: 320, menuCategory: 'Tea', emoji: '🫖', pointsLabel: '+3 pts'),
      const MockMenuItem(id: 12, name: 'Croissant', description: 'Butter croissant, baked fresh daily', price: 280, menuCategory: 'Food', emoji: '🥐', pointsLabel: '+3 pts', isPopular: true),
      const MockMenuItem(id: 13, name: 'Avocado Toast', description: 'Sourdough, smashed avocado, poached egg, chilli flakes', price: 550, menuCategory: 'Food', emoji: '🥑', pointsLabel: '+6 pts'),
      const MockMenuItem(id: 14, name: 'Granola Bowl', description: 'House granola, seasonal berries, Greek yogurt', price: 480, menuCategory: 'Food', emoji: '🍓', pointsLabel: '+5 pts'),
    ],
    3: [ // FitZone Pro
      const MockMenuItem(id: 15, name: 'HIIT Class', description: '45-min high-intensity interval training session', price: 1200, menuCategory: 'Classes', emoji: '🏋️', pointsLabel: '+12 pts', isPopular: true),
      const MockMenuItem(id: 16, name: 'Yoga Flow', description: '60-min vinyasa yoga for all levels', price: 1000, menuCategory: 'Classes', emoji: '🧘', pointsLabel: '+10 pts'),
      const MockMenuItem(id: 17, name: 'Spin Cycle', description: '45-min indoor cycling class with music', price: 1100, menuCategory: 'Classes', emoji: '🚴', pointsLabel: '+11 pts', isPopular: true),
      const MockMenuItem(id: 18, name: 'Personal Training', description: '60-min 1-on-1 with certified trainer', price: 3500, menuCategory: 'Personal', emoji: '💪', pointsLabel: '+35 pts'),
      const MockMenuItem(id: 19, name: 'Recovery Session', description: 'Ice bath + sauna + foam rolling – 30 min', price: 800, menuCategory: 'Recovery', emoji: '🧊', pointsLabel: '+8 pts'),
    ],
    4: [ // Glow Studio
      const MockMenuItem(id: 20, name: 'Blowout & Style', description: 'Wash, blow-dry, and professional styling', price: 2200, menuCategory: 'Hair', emoji: '💇', pointsLabel: '+22 pts', isPopular: true),
      const MockMenuItem(id: 21, name: 'Full Color', description: 'Single process color with toner and glossing', price: 5500, menuCategory: 'Hair', emoji: '🎨', pointsLabel: '+55 pts'),
      const MockMenuItem(id: 22, name: 'Gel Manicure', description: 'Gel polish manicure with nail art option', price: 1800, menuCategory: 'Nails', emoji: '💅', pointsLabel: '+18 pts', isPopular: true),
      const MockMenuItem(id: 23, name: 'Pedicure', description: 'Exfoliation, massage, and gel polish', price: 2200, menuCategory: 'Nails', emoji: '🦶', pointsLabel: '+22 pts'),
      const MockMenuItem(id: 24, name: 'Facial Treatment', description: 'Deep cleansing facial with hyaluronic serum', price: 3500, menuCategory: 'Skin', emoji: '🌸', pointsLabel: '+35 pts'),
    ],
    5: [ // Urban Thread
      const MockMenuItem(id: 25, name: 'Linen Shirt', description: 'Premium linen, relaxed fit, 6 colours', price: 4500, menuCategory: 'Tops', emoji: '👔', pointsLabel: '+45 pts', isPopular: true),
      const MockMenuItem(id: 26, name: 'Wide-Leg Trousers', description: 'High-waist wide leg in sustainable fabric', price: 6500, menuCategory: 'Bottoms', emoji: '👖', pointsLabel: '+65 pts'),
      const MockMenuItem(id: 27, name: 'Leather Tote', description: 'Genuine leather tote, handcrafted locally', price: 12000, menuCategory: 'Accessories', emoji: '👜', pointsLabel: '+120 pts', isPopular: true),
      const MockMenuItem(id: 28, name: 'Silk Scarf', description: '100% mulberry silk, printed in-house', price: 3500, menuCategory: 'Accessories', emoji: '🧣', pointsLabel: '+35 pts'),
    ],
    6: [ // Verde Market
      const MockMenuItem(id: 29, name: 'Organic Basket', description: 'Weekly seasonal organic produce box', price: 2800, menuCategory: 'Bundles', emoji: '🧺', pointsLabel: '+28 pts', isPopular: true),
      const MockMenuItem(id: 30, name: 'Fresh Bread', description: 'Stone-milled sourdough, baked daily', price: 380, menuCategory: 'Bakery', emoji: '🍞', pointsLabel: '+4 pts'),
      const MockMenuItem(id: 31, name: 'Greek Yogurt', description: 'Strained yogurt, 500g, locally made', price: 450, menuCategory: 'Dairy', emoji: '🥛', pointsLabel: '+5 pts'),
      const MockMenuItem(id: 32, name: 'Olive Oil', description: 'Cold-pressed extra virgin, 500ml', price: 1200, menuCategory: 'Pantry', emoji: '🫙', pointsLabel: '+12 pts', isPopular: true),
    ],
    7: [ // Cinema Luxe
      const MockMenuItem(id: 33, name: 'Standard Seat', description: '4K laser projection, Dolby Atmos sound', price: 1000, menuCategory: 'Tickets', emoji: '🎟️', pointsLabel: '+10 pts', isPopular: true),
      const MockMenuItem(id: 34, name: 'VIP Seat', description: 'Recliner seat with table service', price: 2200, menuCategory: 'Tickets', emoji: '👑', pointsLabel: '+22 pts'),
      const MockMenuItem(id: 35, name: 'Popcorn Combo', description: 'Large popcorn + drink of your choice', price: 900, menuCategory: 'Food & Drinks', emoji: '🍿', pointsLabel: '+9 pts', isPopular: true),
      const MockMenuItem(id: 36, name: 'Hot Dog', description: 'Gourmet all-beef hot dog with toppings', price: 700, menuCategory: 'Food & Drinks', emoji: '🌭', pointsLabel: '+7 pts'),
    ],
    8: [ // MedCare Clinic
      const MockMenuItem(id: 37, name: 'GP Consultation', description: 'General practitioner consultation, 30 min', price: 3000, menuCategory: 'Consultations', emoji: '👨‍⚕️', pointsLabel: '+30 pts', isPopular: true),
      const MockMenuItem(id: 38, name: 'Blood Panel', description: 'Full blood count + metabolic panel', price: 5000, menuCategory: 'Diagnostics', emoji: '🩸', pointsLabel: '+50 pts'),
      const MockMenuItem(id: 39, name: 'Dental Checkup', description: 'Exam, X-ray, and cleaning', price: 4500, menuCategory: 'Dental', emoji: '🦷', pointsLabel: '+45 pts', isPopular: true),
      const MockMenuItem(id: 40, name: 'Physio Session', description: '45-min physiotherapy with specialist', price: 4000, menuCategory: 'Therapy', emoji: '🏃', pointsLabel: '+40 pts'),
    ],
  };

  static final recentActivity = transactions.take(5).toList();
  static final businessesWithPoints = businesses.where((b) => b.points > 0).toList();
  static final hotBusinesses = [...businesses]..sort((a, b) => b.rating.compareTo(a.rating));

  static List<MockCoupon> couponsForBusiness(int businessId) =>
      coupons.where((c) => c.businessId == businessId).toList();

  static List<MockOffer> offersForBusiness(int businessId) =>
      hotOffers.where((o) => o.businessId == businessId).toList();

  static List<MockReward> rewardsForBusiness(int businessId) =>
      rewards.where((r) => r.businessId == businessId).toList();

  static List<MockTransaction> transactionsForBusiness(int businessId) =>
      transactions.where((t) => t.businessId == businessId).toList();
}

class _MockCustomer {
  const _MockCustomer({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.lifetimePoints,
    required this.currentPoints,
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
  final int lifetimePoints;
  final int currentPoints;
  final int spentPoints;
  final int businessesVisited;
  final int activeCoupons;
  final int activeRewards;
  final String memberSince;
  final String memberCode;
  final List<String> roles;

  String get fullName => '$firstName $lastName';
  String get initials => '${firstName[0]}${lastName[0]}';
}
