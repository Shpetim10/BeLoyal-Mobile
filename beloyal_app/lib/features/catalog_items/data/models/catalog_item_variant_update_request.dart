class CatalogItemVariantUpdateRequest {
  final int? catalogItemId;
  final String? name;
  final String? description;
  final double? priceOverride;

  CatalogItemVariantUpdateRequest({
    this.catalogItemId,
    this.name,
    this.description,
    this.priceOverride,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (catalogItemId != null) data['catalogItemId'] = catalogItemId;
    if (name != null) data['name'] = name;
    // We might need to handle null values for clearing them, 
    // but typically we can just include keys if they are passed.
    // Assuming `null` actually clears it:
    if (description != null) data['description'] = description;
    if (priceOverride != null) data['priceOverride'] = priceOverride;
    // Wait, the API says "Sending a field as null will clear its value".
    // This is tricky in Dart without a special marker. We'll add a `clearDescription` 
    // and `clearPrice` or just always send them if they are passed in a map.
    // For simplicity, let's just make a map manually when calling update.
    return data;
  }
}
