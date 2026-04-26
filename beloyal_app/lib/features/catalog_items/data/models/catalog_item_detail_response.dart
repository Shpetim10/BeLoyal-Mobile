import 'catalog_item_status.dart';

class CatalogItemDetailResponse {
  final int id;
  final String name;
  final String? description;
  final CatalogItemStatus status;
  final String? categoryName;
  final int? categoryId;
  final double price;
  final String? type;
  final String? currencyCode;
  final String? unit;
  final int orderIndex;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const CatalogItemDetailResponse({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    this.categoryName,
    this.categoryId,
    required this.price,
    this.type,
    this.currencyCode,
    this.unit,
    required this.orderIndex,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory CatalogItemDetailResponse.fromJson(Map<String, dynamic> json) {
    String? _safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is String) return DateTime.tryParse(value);
      if (value is List && value.length >= 3) {
        // [year, month, day, hour, minute, second, nano]
        return DateTime(
          value[0] as int,
          value[1] as int,
          value[2] as int,
          value.length >= 4 ? value[3] as int : 0,
          value.length >= 5 ? value[4] as int : 0,
          value.length >= 6 ? value[5] as int : 0,
        );
      }
      return null;
    }

    bool _parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    return CatalogItemDetailResponse(
      id: json['id'] as int,
      name: _safeString(json['name']) ?? '',
      description: _safeString(json['description']),
      status: CatalogItemStatus.fromString(_safeString(json['status']) ?? 'INACTIVE'),
      categoryName: _safeString(json['categoryName']),
      categoryId: json['categoryId'] as int?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      type: _safeString(json['type']),
      currencyCode: _safeString(json['currency']) ?? _safeString(json['currencyCode']),
      unit: _safeString(json['unit']),
      orderIndex: json['orderIndex'] as int? ?? 0,
      imageUrl: _safeString(json['imageUrl']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      isDeleted: _parseBool(json['isDeleted']),
    );
  }
}


