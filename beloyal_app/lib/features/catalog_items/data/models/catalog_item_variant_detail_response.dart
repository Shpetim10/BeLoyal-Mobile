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
    return CatalogItemVariantDetailResponse(
      id: json['id'] as int,
      catalogItemId: json['catalogItemId'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceOverride: (json['priceOverride'] as num?)?.toDouble(),
      status: json['status'] as String,
      orderIndex: json['orderIndex'] as int,
      isDeleted: json['isDeleted'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
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
