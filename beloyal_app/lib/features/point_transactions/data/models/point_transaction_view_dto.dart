class PointTransactionViewDto {
  PointTransactionViewDto({
    required this.id,
    required this.customerFullName,
    this.customerEmail,
    this.customerPhone,
    required this.businessName,
    required this.availablePoints,
    required this.lifetimeEarnedPoints,
    required this.lifetimeExpired,
    this.lastActivityAt,
    this.invoiceReference,
    this.note,
    required this.netAmount,
    this.discountAmount,
    required this.billAmount,
    required this.businessMemberFullName,
    required this.type,
    this.description,
    this.reason,
    required this.pointsDelta,
    this.ruleAmountPer,
    this.rulePointsPer,
    required this.createdAt,
  });

  factory PointTransactionViewDto.fromJson(Map<String, dynamic> json) {
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

    return PointTransactionViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerFullName: getString('customerFullName') ?? 'Unknown Customer',
      customerEmail: getString('customerEmail'),
      customerPhone: getString('customerPhone'),
      businessName: getString('businessName') ?? 'Unknown Business',
      availablePoints: (json['availablePoints'] as num?)?.toInt() ?? 0,
      lifetimeEarnedPoints: (json['lifetimeEarnedPoints'] as num?)?.toInt() ?? 0,
      lifetimeExpired: (json['lifetimeExpired'] as num?)?.toInt() ?? 0,
      lastActivityAt: parseDate(json['lastActivityAt']),
      invoiceReference: getString('invoiceReference'),
      note: getString('note'),
      netAmount: (json['netAmount'] as num?)?.toDouble() ?? 0.0,
      discountAmount: (json['discountAmount'] as num?)?.toDouble(),
      billAmount: (json['billAmount'] as num?)?.toDouble() ?? 0.0,
      businessMemberFullName: getString('businessMemberFullName') ?? 'Unknown Staff',
      type: getString('type') ?? 'UNKNOWN',
      description: getString('description'),
      reason: getString('reason'),
      pointsDelta: (json['pointsDelta'] as num?)?.toInt() ?? 0,
      ruleAmountPer: (json['ruleAmountPer'] as num?)?.toDouble(),
      rulePointsPer: (json['rulePointsPer'] as num?)?.toInt(),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
    );
  }

  final int id;
  final String customerFullName;
  final String? customerEmail;
  final String? customerPhone;
  final String businessName;
  final int availablePoints;
  final int lifetimeEarnedPoints;
  final int lifetimeExpired;
  final DateTime? lastActivityAt;
  final String? invoiceReference;
  final String? note;
  final double netAmount;
  final double? discountAmount;
  final double billAmount;
  final String businessMemberFullName;
  final String type;
  final String? description;
  final String? reason;
  final int pointsDelta;
  final double? ruleAmountPer;
  final int? rulePointsPer;
  final DateTime createdAt;
}
