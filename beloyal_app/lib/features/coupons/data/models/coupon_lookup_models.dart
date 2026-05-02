class CategoryLookup {
  const CategoryLookup({
    required this.id,
    required this.name,
    required this.status,
  });

  final int id;
  final String name;
  final String status;

  factory CategoryLookup.fromJson(Map<String, dynamic> json) => CategoryLookup(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
      );
}

class ProductLookup {
  const ProductLookup({
    required this.id,
    required this.name,
    required this.categoryId,
    this.imageUrl,
    required this.status,
  });

  final int id;
  final String name;
  final int categoryId;
  final String? imageUrl;
  final String status;

  factory ProductLookup.fromJson(Map<String, dynamic> json) => ProductLookup(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        categoryId: (json['categoryId'] as num?)?.toInt() ?? 0,
        imageUrl: json['imageUrl']?.toString(),
        status: json['status']?.toString() ?? 'ACTIVE',
      );
}

class VariantLookup {
  const VariantLookup({
    required this.id,
    required this.name,
    required this.status,
    this.price,
    this.currency,
  });

  final int id;
  final String name;
  final String status;
  final double? price;
  final String? currency;

  factory VariantLookup.fromJson(Map<String, dynamic> json) => VariantLookup(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        status: json['status']?.toString() ?? 'ACTIVE',
        price: json['price'] != null ? (json['price'] as num).toDouble() : null,
        currency: json['currency']?.toString(),
      );

  String get priceLabel {
    if (price == null) return '';
    final sym = currency ?? '';
    return '$sym ${price!.toStringAsFixed(2)}'.trim();
  }
}

class CouponImageUploadResponse {
  const CouponImageUploadResponse({
    required this.url,
    required this.key,
    required this.contentType,
    required this.sizeBytes,
  });

  final String url;
  final String key;
  final String contentType;
  final int sizeBytes;

  factory CouponImageUploadResponse.fromJson(Map<String, dynamic> json) =>
      CouponImageUploadResponse(
        url: json['url']?.toString() ?? '',
        key: json['key']?.toString() ?? '',
        contentType: json['contentType']?.toString() ?? '',
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      );
}
