class PointTransactionCustomerAllListViewDto {
  PointTransactionCustomerAllListViewDto({
    required this.id,
    required this.businessName,
    required this.businessLocation,
    this.businessLogoPath,
    this.billTransactionReferenceId,
    required this.type,
    required this.points,
    required this.netAmount,
    this.discountAmount,
    required this.billAmount,
    required this.createdAt,
  });

  factory PointTransactionCustomerAllListViewDto.fromJson(Map<String, dynamic> json) {
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

    return PointTransactionCustomerAllListViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: json['businessName']?.toString() ?? 'Unknown Business',
      businessLocation: json['businessLocation']?.toString() ?? '',
      businessLogoPath: json['businessLogoPath']?.toString(),
      billTransactionReferenceId: json['billTransactionReferenceId']?.toString(),
      type: json['type']?.toString() ?? 'UNKNOWN',
      points: (json['points'] as num?)?.toInt() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final int id;
  final String businessName;
  final String businessLocation;
  final String? businessLogoPath;
  final String? billTransactionReferenceId;
  final String type;
  final int points;
  final double netAmount;
  final double? discountAmount;
  final double billAmount;
  final DateTime createdAt;
}

class PointTransactionCustomerBusinessListViewDto {
  PointTransactionCustomerBusinessListViewDto({
    required this.id,
    this.billTransactionReferenceId,
    required this.type,
    required this.points,
    required this.netAmount,
    this.discountAmount,
    required this.billAmount,
    required this.createdAt,
  });

  factory PointTransactionCustomerBusinessListViewDto.fromJson(Map<String, dynamic> json) {
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

    return PointTransactionCustomerBusinessListViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      billTransactionReferenceId: json['billTransactionReferenceId']?.toString(),
      type: json['type']?.toString() ?? 'UNKNOWN',
      points: (json['points'] as num?)?.toInt() ?? 0,
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final int id;
  final String? billTransactionReferenceId;
  final String type;
  final int points;
  final double netAmount;
  final double? discountAmount;
  final double billAmount;
  final DateTime createdAt;
}
