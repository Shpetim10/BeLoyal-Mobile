import 'catalog_item_type.dart';

class CatalogItemCreateRequest {
  final String name;
  final String? description;
  final double price;
  final CatalogItemType type;
  final String currency; // Assuming CurrencyCode maps to a String currency code like 'USD' or 'EUR'
  final String? unit;
  final String? imageUrl;
  final String? imageKey;

  const CatalogItemCreateRequest({
    required this.name,
    this.description,
    required this.price,
    required this.type,
    required this.currency,
    this.unit,
    this.imageUrl,
    this.imageKey,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty) 'description': description!.trim(),
      'price': price,
      'type': type.backendValue,
      'currency': currency,
      if (unit != null && unit!.trim().isNotEmpty) 'unit': unit!.trim(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imageKey != null) 'imageKey': imageKey,
    };
  }
}
