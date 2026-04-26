class CatalogCategoryShortResponse {
  final int id;
  final String name;

  const CatalogCategoryShortResponse({
    required this.id,
    required this.name,
  });

  factory CatalogCategoryShortResponse.fromJson(Map<String, dynamic> json) {
    return CatalogCategoryShortResponse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}
