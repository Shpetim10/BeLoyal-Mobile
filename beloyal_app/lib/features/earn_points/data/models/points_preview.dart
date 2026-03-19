/// Backend response for a points calculation preview.
///
/// Endpoint: GET /business/{id}/transactions/earn-points/preview
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
    this.transactionReference,
    this.note,
  });

  /// Total points that will be awarded across all guests in this transaction.
  final int totalPoints;

  /// Remaining capacity before hitting the max-per-transaction cap.
  final int remainingPoints;

  /// The primary (first) customer in the allocation.
  final int primaryCustomerId;

  /// Points awarded per [amountPer] ALL.
  final int pointsPer;

  /// The ALL threshold required to earn [pointsPer] points.
  final double amountPer;

  /// Maximum points that can be earned in a single transaction.
  final int maxPointsPerTransaction;

  /// Per-guest breakdown of earned points and current balance.
  final List<GuestPointsResult> guestPointsResults;

  /// Total bill amount (from final response).
  final double? billAmount;

  /// Unique transaction reference (from final response).
  final String? transactionReference;

  /// Staff note (from final response).
  final String? note;

  factory PointsPreview.fromJson(Map<String, dynamic> json) {
    return PointsPreview(
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      remainingPoints: (json['remainingPoints'] as num?)?.toInt() ?? 0,
      primaryCustomerId: (json['primaryCustomerId'] as num?)?.toInt() ?? 0,
      pointsPer: (json['pointsPer'] as num?)?.toInt() ?? 0,
      amountPer: (json['amountPer'] as num?)?.toDouble() ?? 0.0,
      maxPointsPerTransaction:
          (json['maxPointsPerTransaction'] as num?)?.toInt() ?? 0,
      guestPointsResults: (json['guestPointsResults'] as List<dynamic>?)
              ?.map(
                (e) => GuestPointsResult.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      billAmount: (json['billAmount'] as num?)?.toDouble(),
      transactionReference: json['transactionReference'] as String?,
      note: json['note'] as String?,
    );
  }

  /// Human-readable earning rule summary, e.g. "1 pt per 100 ALL".
  String get earningRuleSummary => '$pointsPer pt per ${amountPer.toStringAsFixed(amountPer.truncateToDouble() == amountPer ? 0 : 2)} ALL';
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
