import 'coupon_enums.dart';

DateTime? parseCouponDate(dynamic v) {
  if (v == null) return null;
  if (v is String) return DateTime.tryParse(v);
  if (v is List && v.length >= 3) {
    return DateTime(
      (v[0] as num).toInt(),
      (v[1] as num).toInt(),
      (v[2] as num).toInt(),
      v.length > 3 ? (v[3] as num).toInt() : 0,
      v.length > 4 ? (v[4] as num).toInt() : 0,
    );
  }
  return null;
}

class CouponSummary {
  const CouponSummary({
    required this.id,
    required this.type,
    required this.title,
    this.imageUrl,
    required this.pointsCost,
    required this.currency,
    required this.status,
    required this.visibility,
    required this.startDate,
    required this.endDate,
    this.totalRedemptionLimit,
    required this.totalRedemptions,
    required this.isFeatured,
    required this.createdAt,
  });

  final int id;
  final CouponType type;
  final String title;
  final String? imageUrl;
  final int pointsCost;
  final CouponCurrency currency;
  final CouponStatus status;
  final CouponVisibility visibility;
  final DateTime startDate;
  final DateTime endDate;
  final int? totalRedemptionLimit;
  final int totalRedemptions;
  final bool isFeatured;
  final DateTime createdAt;

  factory CouponSummary.fromJson(Map<String, dynamic> json) {
    return CouponSummary(
      id: (json['id'] as num).toInt(),
      type: CouponType.fromBackend(json['type']?.toString() ?? ''),
      title: json['title']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      pointsCost: (json['pointsCost'] as num?)?.toInt() ?? 0,
      currency: CouponCurrency.fromBackend(json['currency']?.toString() ?? 'LEK'),
      status: CouponStatus.fromBackend(json['status']?.toString() ?? 'DRAFT'),
      visibility: CouponVisibility.fromBackend(json['visibility']?.toString() ?? 'PUBLIC'),
      startDate: parseCouponDate(json['startDate']) ?? DateTime.now(),
      endDate: parseCouponDate(json['endDate']) ?? DateTime.now(),
      totalRedemptionLimit: (json['totalRedemptionLimit'] as num?)?.toInt(),
      totalRedemptions: (json['totalRedemptions'] as num?)?.toInt() ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: parseCouponDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get hasRedemptionLimit => totalRedemptionLimit != null;
  bool get isAtLimit =>
      totalRedemptionLimit != null && totalRedemptions >= totalRedemptionLimit!;
}

class CouponPage {
  const CouponPage({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.isFirst,
    required this.isLast,
  });

  final List<CouponSummary> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool isFirst;
  final bool isLast;

  factory CouponPage.fromJson(Map<String, dynamic> json) {
    final contentList = json['content'] as List<dynamic>? ?? [];
    return CouponPage(
      content: contentList
          .map((e) => CouponSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      number: (json['number'] as num?)?.toInt() ?? 0,
      size: (json['size'] as num?)?.toInt() ?? 20,
      totalElements: (json['totalElements'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      isFirst: json['first'] as bool? ?? true,
      isLast: json['last'] as bool? ?? true,
    );
  }
}
