class PointTransactionStaffListViewDto {
  PointTransactionStaffListViewDto({
    required this.id,
    required this.customerFullName,
    this.billTransactionReferenceId,
    required this.type,
    required this.points,
    required this.netAmount,
    this.discountAmount,
    required this.billAmount,
    required this.createdAt,
  });

  factory PointTransactionStaffListViewDto.fromJson(Map<String, dynamic> json) {
    String? getString(String key) {
      final v = json[key];
      if (v == null) return null;
      if (v is String) return v;
      if (v is Iterable) return v.join(', ');
      return v.toString();
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is List && v.isNotEmpty) {
        int year = v.length > 0 ? (v[0] as num).toInt() : 1970;
        int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    return PointTransactionStaffListViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerFullName: getString('customerFullName') ?? 'Unknown Customer',
      billTransactionReferenceId: getString('billTransactionReferenceId'),
      type: getString('type') ?? 'UNKNOWN',
      points: (json['points'] as num?)?.toInt() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final int id;
  final String customerFullName;
  final String? billTransactionReferenceId;
  final String type;
  final int points;
  final double netAmount;
  final double? discountAmount;
  final double billAmount;
  final DateTime createdAt;
}
