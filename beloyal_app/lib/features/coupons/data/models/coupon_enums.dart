import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

enum CouponType {
  freeProduct,
  percentageDiscount,
  fixedAmountDiscount;

  static CouponType fromBackend(String raw) => switch (raw.toUpperCase()) {
    'FREE_PRODUCT' => CouponType.freeProduct,
    'PERCENTAGE_DISCOUNT' => CouponType.percentageDiscount,
    'FIXED_AMOUNT_DISCOUNT' => CouponType.fixedAmountDiscount,
    _ => CouponType.freeProduct,
  };

  String get backendValue => switch (this) {
    CouponType.freeProduct => 'FREE_PRODUCT',
    CouponType.percentageDiscount => 'PERCENTAGE_DISCOUNT',
    CouponType.fixedAmountDiscount => 'FIXED_AMOUNT_DISCOUNT',
  };

  String get displayName => switch (this) {
    CouponType.freeProduct => 'Free Product',
    CouponType.percentageDiscount => 'Percentage Discount',
    CouponType.fixedAmountDiscount => 'Fixed Amount Discount',
  };

  String get shortLabel => switch (this) {
    CouponType.freeProduct => 'Free Product',
    CouponType.percentageDiscount => '% Off',
    CouponType.fixedAmountDiscount => 'Fixed Off',
  };

  IconData get icon => switch (this) {
    CouponType.freeProduct => Icons.card_giftcard,
    CouponType.percentageDiscount => Icons.percent,
    CouponType.fixedAmountDiscount => Icons.discount,
  };

  Color get color => switch (this) {
    CouponType.freeProduct => AppColors.couponTypeFreeProduct,
    CouponType.percentageDiscount => AppColors.couponTypePercentage,
    CouponType.fixedAmountDiscount => AppColors.couponTypeFixedAmount,
  };
}

enum CouponStatus {
  draft,
  active,
  paused,
  expired,
  archived;

  static CouponStatus fromBackend(String raw) => switch (raw.toUpperCase()) {
    'DRAFT' => CouponStatus.draft,
    'ACTIVE' => CouponStatus.active,
    'PAUSED' => CouponStatus.paused,
    'EXPIRED' => CouponStatus.expired,
    'ARCHIVED' => CouponStatus.archived,
    _ => CouponStatus.draft,
  };

  String get backendValue => name.toUpperCase();

  String get displayName => switch (this) {
    CouponStatus.draft => 'Draft',
    CouponStatus.active => 'Active',
    CouponStatus.paused => 'Paused',
    CouponStatus.expired => 'Expired',
    CouponStatus.archived => 'Archived',
  };

  Color get color => switch (this) {
    CouponStatus.draft => AppColors.couponStatusDraft,
    CouponStatus.active => AppColors.couponStatusActive,
    CouponStatus.paused => AppColors.couponStatusPaused,
    CouponStatus.expired => AppColors.couponStatusExpired,
    CouponStatus.archived => AppColors.couponStatusArchived,
  };

  List<CouponStatus> get allowedTransitions => switch (this) {
    CouponStatus.draft => [CouponStatus.active, CouponStatus.archived],
    CouponStatus.active => [
      CouponStatus.paused,
      CouponStatus.expired,
      CouponStatus.archived,
    ],
    CouponStatus.paused => [CouponStatus.active, CouponStatus.archived],
    CouponStatus.expired => [CouponStatus.archived],
    CouponStatus.archived => [CouponStatus.draft],
  };
}

enum CouponVisibility {
  public,
  hidden;

  static CouponVisibility fromBackend(String raw) =>
      raw.toUpperCase() == 'PUBLIC'
      ? CouponVisibility.public
      : CouponVisibility.hidden;

  String get backendValue => name.toUpperCase();

  String get displayName => switch (this) {
    CouponVisibility.public => 'Public',
    CouponVisibility.hidden => 'Hidden',
  };

  Color get color => switch (this) {
    CouponVisibility.public => AppColors.couponVisibilityPublic,
    CouponVisibility.hidden => AppColors.couponVisibilityHidden,
  };

  IconData get icon => switch (this) {
    CouponVisibility.public => Icons.public,
    CouponVisibility.hidden => Icons.visibility_off,
  };
}

enum CouponCurrency {
  lek,
  dollar,
  euro;

  static CouponCurrency fromBackend(String raw) => switch (raw.toUpperCase()) {
    'LEK' => CouponCurrency.lek,
    'ALL' => CouponCurrency.lek,
    'DOLLAR' => CouponCurrency.dollar,
    'USD' => CouponCurrency.dollar,
    'EURO' => CouponCurrency.euro,
    'EUR' => CouponCurrency.euro,
    _ => CouponCurrency.lek,
  };

  String get backendValue => switch (this) {
    CouponCurrency.lek => 'LEK',
    CouponCurrency.dollar => 'DOLLAR',
    CouponCurrency.euro => 'EURO',
  };

  String get symbol => switch (this) {
    CouponCurrency.lek => 'ALL',
    CouponCurrency.dollar => '\$',
    CouponCurrency.euro => '€',
  };

  String get displayCode => switch (this) {
    CouponCurrency.lek => 'ALL',
    CouponCurrency.dollar => 'USD',
    CouponCurrency.euro => 'EUR',
  };
}
