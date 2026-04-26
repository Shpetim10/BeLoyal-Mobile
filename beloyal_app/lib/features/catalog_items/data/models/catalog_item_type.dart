// lib/features/catalog_items/data/models/catalog_item_type.dart
enum CatalogItemType {
  product,
  service;

  static CatalogItemType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'product':
        return CatalogItemType.product;
      case 'service':
        return CatalogItemType.service;
      default:
        return CatalogItemType.product;
    }
  }

  String get backendValue {
    switch (this) {
      case CatalogItemType.product:
        return 'PRODUCT';
      case CatalogItemType.service:
        return 'SERVICE';
    }
  }

  String get displayName {
    switch (this) {
      case CatalogItemType.product:
        return 'Product';
      case CatalogItemType.service:
        return 'Service';
    }
  }
}
