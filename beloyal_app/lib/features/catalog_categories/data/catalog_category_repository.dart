import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'models/catalog_category.dart';
import 'models/catalog_category_short_response.dart';

/// Repository for all Catalog Category API operations.
///
/// Base path: business/{businessId}/catalog-category
///
/// Currently implemented:
///   - GET all categories
///   - GET one category by id
///   - POST create category
///
/// Stubbed for future implementation or consolidated:
///   - Generic PATCH  update (handles all fields)
///   - Generic PATCH  reorder
///   - DELETE delete
class CatalogCategoryRepository {
  CatalogCategoryRepository(this._dio);

  final Dio _dio;

  String _base(int businessId) => '/business/$businessId/catalog-category';

  // ── GET All ───────────────────────────────────────────────────────────────

  /// Fetches all categories for a business, ordered by [orderIndex].
  Future<List<CatalogCategory>> getAll({required int businessId}) async {
    final response = await _dio.get(_base(businessId));
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches categories from trash.
  ///
  /// Backend:
  ///   GET /business/{businessId}/catalog-category/trash
  Future<List<CatalogCategory>> getTrash({required int businessId}) async {
    final response = await _dio.get('${_base(businessId)}/trash');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches only active categories, using the short response DTO.
  Future<List<CatalogCategoryShortResponse>> getActiveShort({
    required int businessId,
  }) async {
    final response = await _dio.get('${_base(businessId)}/active');
    final list = response.data as List<dynamic>;
    return list
        .map(
          (e) =>
              CatalogCategoryShortResponse.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  // ── GET One ───────────────────────────────────────────────────────────────

  /// Fetches a single category by [categoryId].
  Future<CatalogCategory> getById({
    required int businessId,
    required int categoryId,
  }) async {
    final response = await _dio.get('${_base(businessId)}/$categoryId');
    return CatalogCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ── POST Create ───────────────────────────────────────────────────────────

  /// Creates a new category.
  ///
  /// Backend validation:
  ///   - name: required, not blank, max 120 chars
  ///   - description: optional, max 300 chars
  Future<CatalogCategory> create({
    required int businessId,
    required String name,
    String? description,
  }) async {
    final body = <String, dynamic>{'name': name.trim()};
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    final response = await _dio.post(_base(businessId), data: body);
    return CatalogCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH Update ───────────────────────────────────────────────────────────
  //
  // Backend contract:
  //   PATCH /api/besahub/business/{businessId}/catalog-category/{id}
  //   Body: { "name": string?, "description": string?, "status": string?, "orderIndex": int? }
  //
  // Using JsonNullable on the backend allows partial updates.
  Future<CatalogCategory> update({
    required int businessId,
    required int categoryId,
    String? name,
    String? description,
    bool clearDescription = false,
    CategoryStatus? status,
    int? orderIndex,
  }) async {
    final body = <String, dynamic>{};

    if (name != null && name.trim().isNotEmpty) body['name'] = name.trim();

    if (description != null) {
      if (description.trim().isEmpty) {
        // The user erased the text field, explicitly set to null
        body['description'] = null;
      } else {
        // They gave a valid new description
        body['description'] = description.trim();
      }
    } else if (clearDescription) {
      body['description'] = null;
    }

    if (status != null) body['status'] = status.name.toUpperCase();
    if (orderIndex != null) body['orderIndex'] = orderIndex;

    final response = await _dio.patch(
      '${_base(businessId)}/$categoryId',
      data: body,
    );
    return CatalogCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH Activate ────────────────────────────────────────────────────────
  //
  // Expected contract:
  //   PATCH /api/besahub/business/{businessId}/catalog-category/{id}/activate
  //   Response: CatalogCategory JSON with status "ACTIVE"
  Future<CatalogCategory> activate({
    required int businessId,
    required int categoryId,
  }) async {
    final response = await _dio.patch(
      '${_base(businessId)}/$categoryId/activate',
    );
    return CatalogCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ── PATCH Deactivate ──────────────────────────────────────────────────────
  //
  // Expected contract:
  //   PATCH /api/besahub/business/{businessId}/catalog-category/{id}/deactivate
  //   Response: CatalogCategory JSON with status "INACTIVE"
  Future<CatalogCategory> deactivate({
    required int businessId,
    required int categoryId,
  }) async {
    final response = await _dio.patch(
      '${_base(businessId)}/$categoryId/deactivate',
    );
    return CatalogCategory.fromJson(response.data as Map<String, dynamic>);
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────
  //
  // Expected contract:
  //   DELETE /api/besahub/business/{businessId}/catalog-category/{id}
  //   Response: 204 No Content
  Future<void> delete({
    required int businessId,
    required int categoryId,
  }) async {
    await _dio.delete('${_base(businessId)}/$categoryId');
  }

  // ── PATCH Restore ────────────────────────────────────────────────────────
  //
  // Expected contract:
  //   PATCH /api/besahub/business/{businessId}/catalog-category/{id}/restore
  //
  // Response may be a status payload; refresh list after calling.
  Future<void> restore({
    required int businessId,
    required int categoryId,
  }) async {
    await _dio.patch('${_base(businessId)}/$categoryId/restore');
  }

  // ── PATCH Reorder ─────────────────────────────────────────────────────────
  //
  // Backend contract:
  //   PATCH /api/besahub/business/{businessId}/catalog-category/reorder
  //   Body: { "categoryOrders": [ { "categoryId": 1, "orderIndex": 0 }, ... ] }
  //
  // Returns the list of all categories after update.
  Future<List<CatalogCategory>> reorder({
    required int businessId,
    required List<int> orderedIds,
  }) async {
    final body = {
      'categoryOrders': orderedIds
          .asMap()
          .entries
          .map((entry) => {'categoryId': entry.value, 'orderIndex': entry.key})
          .toList(),
    };
    final response = await _dio.patch(
      '${_base(businessId)}/reorder',
      data: body,
    );
    final list = response.data as List<dynamic>;
    return list
        .map((e) => CatalogCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

final catalogCategoryRepositoryProvider = Provider<CatalogCategoryRepository>((
  ref,
) {
  return CatalogCategoryRepository(ref.watch(dioProvider));
});

final activeCatalogCategoriesProvider = FutureProvider.family
    .autoDispose<List<CatalogCategoryShortResponse>, int>((
      ref,
      businessId,
    ) async {
      return ref
          .watch(catalogCategoryRepositoryProvider)
          .getActiveShort(businessId: businessId);
    });

final allCatalogCategoriesProvider = FutureProvider.family
    .autoDispose<List<CatalogCategory>, int>((ref, businessId) async {
      return ref
          .watch(catalogCategoryRepositoryProvider)
          .getAll(businessId: businessId);
    });
