/// Expiry type enum matching backend ExpiryType enum.
enum ExpiryType {
  noExpiry,
  expireAfterXMonths;

  String toJson() => switch (this) {
    ExpiryType.noExpiry => 'NO_EXPIRY',
    ExpiryType.expireAfterXMonths => 'EXPIRE_AFTER_X_MONTHS',
  };

  static ExpiryType fromJson(String? raw) =>
      switch (raw?.toUpperCase().trim()) {
        'EXPIRE_AFTER_X_MONTHS' => ExpiryType.expireAfterXMonths,
        _ => ExpiryType.noExpiry,
      };

  String get displayLabel => switch (this) {
    ExpiryType.noExpiry => 'No expiry',
    ExpiryType.expireAfterXMonths => 'Expire after X months',
  };
}

/// DTO returned by GET /business/{id}/loyalty-settings.
class LoyaltySettingsDto {
  const LoyaltySettingsDto({
    required this.minPointsToRedeem,
    required this.maxPointsToRedeem,
    required this.pointsPerUnitDiscount,
    required this.maxPointsPerTransaction,
    required this.expiryType,
    this.monthsToExpire,
  });

  final int minPointsToRedeem;
  final int maxPointsToRedeem;
  final int pointsPerUnitDiscount;
  final int maxPointsPerTransaction;
  final ExpiryType expiryType;
  final int? monthsToExpire;

  factory LoyaltySettingsDto.fromJson(Map<String, dynamic> json) {
    return LoyaltySettingsDto(
      minPointsToRedeem: (json['minPointsToRedeem'] as num?)?.toInt() ?? 1,
      maxPointsToRedeem: (json['maxPointsToRedeem'] as num?)?.toInt() ?? 5000,
      pointsPerUnitDiscount:
          (json['pointsPerUnitDiscount'] as num?)?.toInt() ?? 1,
      maxPointsPerTransaction:
          (json['maxPointsPerTransaction'] as num?)?.toInt() ?? 0,
      expiryType: ExpiryType.fromJson(json['expiryType'] as String?),
      monthsToExpire: (json['monthsToExpire'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minPointsToRedeem': minPointsToRedeem,
      'maxPointsToRedeem': maxPointsToRedeem,
      'pointsPerUnitDiscount': pointsPerUnitDiscount,
      'maxPointsPerTransaction': maxPointsPerTransaction,
      'expiryType': expiryType.toJson(),
      if (expiryType == ExpiryType.expireAfterXMonths && monthsToExpire != null)
        'monthsToExpire': monthsToExpire,
    };
  }

  /// MVP default preset.
  static const mvpDefault = LoyaltySettingsDto(
    minPointsToRedeem: 100,
    maxPointsToRedeem: 5000,
    pointsPerUnitDiscount: 1,
    maxPointsPerTransaction: 5000,
    expiryType: ExpiryType.noExpiry,
  );

  LoyaltySettingsDto copyWith({
    int? minPointsToRedeem,
    int? maxPointsToRedeem,
    int? pointsPerUnitDiscount,
    int? maxPointsPerTransaction,
    ExpiryType? expiryType,
    int? monthsToExpire,
    bool clearMonthsToExpire = false,
  }) {
    return LoyaltySettingsDto(
      minPointsToRedeem: minPointsToRedeem ?? this.minPointsToRedeem,
      maxPointsToRedeem: maxPointsToRedeem ?? this.maxPointsToRedeem,
      pointsPerUnitDiscount:
          pointsPerUnitDiscount ?? this.pointsPerUnitDiscount,
      maxPointsPerTransaction:
          maxPointsPerTransaction ?? this.maxPointsPerTransaction,
      expiryType: expiryType ?? this.expiryType,
      monthsToExpire: clearMonthsToExpire
          ? null
          : (monthsToExpire ?? this.monthsToExpire),
    );
  }
}
