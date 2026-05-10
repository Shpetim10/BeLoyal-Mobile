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
    this.hasLogo = true,
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
  final bool hasLogo;
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

class CustomerMenuItem {
  const CustomerMenuItem({
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
