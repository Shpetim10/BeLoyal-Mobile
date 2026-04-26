import 'catalog_item_status.dart';

class CatalogItemShortResponse {
  final int id;
  final String name;
  final CatalogItemStatus status;
  final String? categoryName;
  final int? categoryId;
  final double price;
  final String? currencyCode;
  final int orderIndex;
  final String? imageUrl;
  final bool isDeleted;

  const CatalogItemShortResponse({
    required this.id,
    required this.name,
    required this.status,
    this.categoryName,
    this.categoryId,
    required this.price,
    this.currencyCode,
    required this.orderIndex,
    this.imageUrl,
    this.isDeleted = false,
  });

  factory CatalogItemShortResponse.fromJson(Map<String, dynamic> json) {
    String? _safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty) return value.first.toString();
      return value.toString();
    }

    int? _safeInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    bool _parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    int? categoryId = _safeInt(json['categoryId']) ?? _safeInt(json['category_id']);
    if (categoryId == null && json['category'] != null && json['category'] is Map) {
      final catMap = json['category'] as Map;
      categoryId = _safeInt(catMap['id']) ?? _safeInt(catMap['categoryId']) ?? _safeInt(catMap['category_id']);
    }

    return CatalogItemShortResponse(
      id: json['id'] as int,
      name: _safeString(json['name']) ?? '',
      status: CatalogItemStatus.fromString(_safeString(json['status']) ?? 'INACTIVE'),
      categoryName: _safeString(json['categoryName']) ?? (json['category'] != null ? _safeString(json['category']['name']) : null),
      categoryId: categoryId,
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      currencyCode: _safeString(json['currency']) ?? _safeString(json['currencyCode']),
      orderIndex: json['orderIndex'] as int? ?? 0,
      imageUrl: _safeString(json['imageUrl']),
      isDeleted: _parseBool(json['isDeleted']),
    );
  }

  CatalogItemShortResponse copyWith({
    int? id,
    String? name,
    CatalogItemStatus? status,
    String? categoryName,
    int? categoryId,
    double? price,
    String? currencyCode,
    int? orderIndex,
    String? imageUrl,
    bool? isDeleted,
  }) {
    return CatalogItemShortResponse(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      currencyCode: currencyCode ?? this.currencyCode,
      orderIndex: orderIndex ?? this.orderIndex,
      imageUrl: imageUrl ?? this.imageUrl,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}


