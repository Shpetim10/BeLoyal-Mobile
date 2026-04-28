class CatalogItemVariantSummaryResponse {
  final int id;
  final String name;
  final String? description;
  final double? priceOverride;
  final String status;
  final int orderIndex;

  CatalogItemVariantSummaryResponse({
    required this.id,
    required this.name,
    this.description,
    this.priceOverride,
    required this.status,
    required this.orderIndex,
  });

  factory CatalogItemVariantSummaryResponse.fromJson(Map<String, dynamic> json) {
    return CatalogItemVariantSummaryResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceOverride: (json['priceOverride'] as num?)?.toDouble(),
      status: json['status'] as String,
      orderIndex: json['orderIndex'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceOverride': priceOverride,
      'status': status,
      'orderIndex': orderIndex,
    };
  }

  CatalogItemVariantSummaryResponse copyWith({
    int? id,
    String? name,
    String? description,
    double? priceOverride,
    String? status,
    int? orderIndex,
  }) {
    return CatalogItemVariantSummaryResponse(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      priceOverride: priceOverride == null ? this.priceOverride : priceOverride,
      status: status ?? this.status,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
