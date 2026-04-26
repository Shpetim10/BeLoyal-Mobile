class CatalogItemCreateResponse {
  final String name;
  final String? description;
  final double price;
  final String currencyCode;
  final String type;
  final String? unit;
  final String status;
  final String? imageUrl;
  final int? orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CatalogItemCreateResponse({
    required this.name,
    this.description,
    required this.price,
    required this.currencyCode,
    required this.type,
    this.unit,
    required this.status,
    this.imageUrl,
    this.orderIndex,
    this.createdAt,
    this.updatedAt,
  });

  factory CatalogItemCreateResponse.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.parse(value);
      if (value is List && value.length >= 3) {
        // Handle Spring Boot list format: [year, month, day, hour, minute, second, nano]
        return DateTime(
          value[0] as int,
          value[1] as int,
          value[2] as int,
          value.length > 3 ? value[3] as int : 0,
          value.length > 4 ? value[4] as int : 0,
          value.length > 5 ? value[5] as int : 0,
        );
      }
      return null;
    }

    String? _safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return CatalogItemCreateResponse(
      name: _safeString(json['name']) ?? '',
      description: _safeString(json['description']),
      price: (json['price'] as num? ?? 0).toDouble(),
      currencyCode: _safeString(json['currencyCode']) ?? '',
      type: _safeString(json['type']) ?? '',
      unit: _safeString(json['unit']),
      status: _safeString(json['status']) ?? 'ACTIVE',
      imageUrl: _safeString(json['imageUrl']),
      orderIndex: json['orderIndex'] as int?,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}
