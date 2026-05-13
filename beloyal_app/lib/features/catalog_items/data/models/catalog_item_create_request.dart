import 'catalog_item_type.dart';

/// Request model for creating or updating a catalog item.
/// Currency is not included — the business's registered currency applies automatically.
class CatalogItemCreateRequest {
  final String name;
  final String? description;
  final double price;
  final CatalogItemType type;
  final String? unit;
  final String? imageUrl;
  final String? imageKey;

  const CatalogItemCreateRequest({
    required this.name,
    this.description,
    required this.price,
    required this.type,
    this.unit,
    this.imageUrl,
    this.imageKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'price': price,
      'type': type.backendValue,
      if (unit != null && unit!.trim().isNotEmpty) 'unit': unit!.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageKey != null) 'imageKey': imageKey,
    };
  }
}
