/// Backend response for a points calculation preview.
///
/// Endpoint: POST /business/{id}/transactions/earn-points/preview
class PointsPreview {
  const PointsPreview({
    required this.totalPoints,
    required this.remainingPoints,
    required this.primaryCustomerId,
    required this.pointsPer,
    required this.amountPer,
    required this.maxPointsPerTransaction,
    required this.guestPointsResults,
    this.billAmount,
    this.originalBillAmount,
    this.couponDiscountApplied,
    this.appliedCustomerCouponId,
    this.transactionReference,
    this.note,
  });

  final int totalPoints;
  final int remainingPoints;
  final int primaryCustomerId;
  final int pointsPer;
  final double amountPer;
  final int maxPointsPerTransaction;
  final List<GuestPointsResult> guestPointsResults;

  /// Final (post-discount) bill amount.
  final double? billAmount;

  /// Original bill amount before coupon discount (null if no coupon applied).
  final double? originalBillAmount;

  /// Discount amount applied by the coupon (null if no coupon).
  final double? couponDiscountApplied;

  /// ID of the applied CustomerCoupon record (null if no coupon).
  final int? appliedCustomerCouponId;

  final String? transactionReference;
  final String? note;

  bool get hasCouponDiscount =>
      couponDiscountApplied != null && couponDiscountApplied! > 0;

  factory PointsPreview.fromJson(Map<String, dynamic> json) {
    return PointsPreview(
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      remainingPoints: (json['remainingPoints'] as num?)?.toInt() ?? 0,
      primaryCustomerId: (json['primaryCustomerId'] as num?)?.toInt() ?? 0,
      pointsPer: (json['pointsPer'] as num?)?.toInt() ?? 0,
      amountPer: (json['amountPer'] as num?)?.toDouble() ?? 0.0,
      maxPointsPerTransaction:
          (json['maxPointsPerTransaction'] as num?)?.toInt() ?? 0,
      guestPointsResults:
          (json['guestPointsResults'] as List<dynamic>?)
              ?.map(
                (e) => GuestPointsResult.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      billAmount: (json['billAmount'] as num?)?.toDouble(),
      originalBillAmount: (json['originalBillAmount'] as num?)?.toDouble(),
      couponDiscountApplied: (json['couponDiscountApplied'] as num?)
          ?.toDouble(),
      appliedCustomerCouponId: (json['appliedCustomerCouponId'] as num?)
          ?.toInt(),
      transactionReference: json['transactionReference'] as String?,
      note: json['note'] as String?,
    );
  }

  /// Human-readable earning rule summary, e.g. "1 pt per 100 ALL".
  String get earningRuleSummary =>
      '$pointsPer pt per ${amountPer.toStringAsFixed(amountPer.truncateToDouble() == amountPer ? 0 : 2)} ALL';
}

/// Per-guest points result from the preview endpoint.
class GuestPointsResult {
  const GuestPointsResult({
    required this.customerId,
    required this.pointsEarned,
    required this.projectedBalance,
  });

  final int customerId;

  /// Points that will be earned by this guest from this transaction.
  final int pointsEarned;

  /// The guest's balance *after* the preview is applied (projected new balance).
  final int projectedBalance;

  factory GuestPointsResult.fromJson(Map<String, dynamic> json) {
    return GuestPointsResult(
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      pointsEarned: (json['earnedPoints'] as num?)?.toInt() ?? 0,
      projectedBalance: (json['currentBalance'] as num?)?.toInt() ?? 0,
    );
  }
}
