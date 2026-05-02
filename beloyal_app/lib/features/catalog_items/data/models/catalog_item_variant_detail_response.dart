class CatalogItemVariantDetailResponse {
  final int id;
  final int catalogItemId;
  final String name;
  final String? description;
  final double? priceOverride;
  final String status;
  final int orderIndex;
  final bool isDeleted;
  final String createdAt;
  final String updatedAt;

  CatalogItemVariantDetailResponse({
    required this.id,
    required this.catalogItemId,
    required this.name,
    this.description,
    this.priceOverride,
    required this.status,
    required this.orderIndex,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CatalogItemVariantDetailResponse.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return fallback;
    }

    bool parseBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return fallback;
    }

    String parseDate(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is List && value.length >= 3) {
        final y = parseInt(value[0]).toString().padLeft(4, '0');
        final m = parseInt(value[1]).toString().padLeft(2, '0');
        final d = parseInt(value[2]).toString().padLeft(2, '0');
        final h = value.length > 3
            ? parseInt(value[3]).toString().padLeft(2, '0')
            : '00';
        final mi = value.length > 4
            ? parseInt(value[4]).toString().padLeft(2, '0')
            : '00';
        final s = value.length > 5
            ? parseInt(value[5]).toString().padLeft(2, '0')
            : '00';
        return '$y-$m-${d}T$h:$mi:$s';
      }
      return value.toString();
    }

    return CatalogItemVariantDetailResponse(
      id: parseInt(json['id']),
      catalogItemId: parseInt(json['catalogItemId']),
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      priceOverride: (json['priceOverride'] as num?)?.toDouble(),
      status: json['status']?.toString() ?? 'ACTIVE',
      orderIndex: parseInt(json['orderIndex']),
      isDeleted: parseBool(json['isDeleted']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catalogItemId': catalogItemId,
      'name': name,
      'description': description,
      'priceOverride': priceOverride,
      'status': status,
      'orderIndex': orderIndex,
      'isDeleted': isDeleted,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
