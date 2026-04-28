import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'models/catalog_item_short_response.dart';
import 'models/catalog_item_detail_response.dart';
import 'models/catalog_item_create_request.dart';
import 'models/catalog_item_create_response.dart';
import 'models/catalog_item_variant_summary_response.dart';
import 'models/catalog_item_variant_detail_response.dart';
import 'models/catalog_item_variant_update_request.dart';

class CatalogItemRepository {
  CatalogItemRepository(this._dio);

  final Dio _dio;

  Future<List<CatalogItemShortResponse>> getAll({required int businessId, int? categoryId}) async {
    final Map<String, dynamic> queryParams = {};
    if (categoryId != null) {
      queryParams['categoryId'] = categoryId;
    }
    final response = await _dio.get(
      '/business/$businessId/catalog-items',
      queryParameters: queryParams,
    );
    final dataList = response.data is List ? response.data : (response.data['data'] ?? []);
    return (dataList as List).map((x) => CatalogItemShortResponse.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<CatalogItemCreateResponse> createItem({
    required int businessId,
    required int categoryId,
    required CatalogItemCreateRequest request,
  }) async {
    final response = await _dio.post(
      '/business/$businessId/catalog-category/$categoryId/catalog-items',
      data: request.toJson(),
    );
    return CatalogItemCreateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateItem({
    required int businessId,
    required int itemId,
    required CatalogItemCreateRequest request,
  }) async {
    await _dio.patch(
      '/business/$businessId/catalog-items/$itemId',
      data: request.toJson(),
    );
  }

  Future<List<CatalogItemShortResponse>> getDeleted({required int businessId}) async {
    final response = await _dio.get(
      '/business/$businessId/catalog-items/trash',
    );
    final dataList = response.data is List ? response.data : (response.data['data'] ?? []);
    return (dataList as List).map((x) => CatalogItemShortResponse.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<CatalogItemDetailResponse> getById({required int businessId, required int itemId}) async {
    final response = await _dio.get('/business/$businessId/catalog-items/$itemId');
    return CatalogItemDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> activate({required int businessId, required int itemId}) async {
    await _dio.patch('/business/$businessId/catalog-items/$itemId/activate');
  }

  Future<void> deactivate({required int businessId, required int itemId}) async {
    await _dio.patch('/business/$businessId/catalog-items/$itemId/deactivate');
  }
  
  Future<void> restore({required int businessId, required int itemId}) async {
    await _dio.patch(
      '/business/$businessId/catalog-items/$itemId/restore',
    );
  }

  Future<void> delete({required int businessId, required int itemId}) async {
    await _dio.delete('/business/$businessId/catalog-items/$itemId');
  }

  Future<List<CatalogItemShortResponse>> reorder({required int businessId, required int categoryId, required List<int> orderedIds}) async {
    final itemOrders = [];
    for (int i = 0; i < orderedIds.length; i++) {
      itemOrders.add({'itemId': orderedIds[i], 'orderIndex': i});
    }

    final response = await _dio.patch(
      '/business/$businessId/catalog-category/$categoryId/catalog-items/reorder',
      data: {'itemOrders': itemOrders},
    );
    final dataList = response.data is List ? response.data : (response.data['data'] ?? []);
    return (dataList as List).map((x) => CatalogItemShortResponse.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<CatalogItemDetailResponse> moveCategory({required int businessId, required int itemId, required int categoryId}) async {
    final response = await _dio.patch(
      '/business/$businessId/catalog-items/$itemId/move',
      queryParameters: {'newCategoryId': categoryId},
    );
    return CatalogItemDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  // --- Variants API ---

  Future<List<CatalogItemVariantSummaryResponse>> getVariants({required int businessId, required int itemId}) async {
    final response = await _dio.get('/business/$businessId/catalog-item/$itemId/variants');
    final dataList = response.data is List ? response.data : (response.data['data'] ?? []);
    return (dataList as List).map((x) => CatalogItemVariantSummaryResponse.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<CatalogItemVariantDetailResponse> getVariantById({required int businessId, required int itemId, required int variantId}) async {
    final response = await _dio.get('/business/$businessId/catalog-item/$itemId/variants/$variantId');
    return CatalogItemVariantDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CatalogItemVariantDetailResponse> createVariant({required int businessId, required int itemId, required CatalogItemVariantUpdateRequest request}) async {
    // Reusing UpdateRequest for create as well
    final response = await _dio.post(
      '/business/$businessId/catalog-item/$itemId/variants',
      data: request.toJson(),
    );
    return CatalogItemVariantDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CatalogItemVariantDetailResponse> updateVariant({required int businessId, required int itemId, required int variantId, required CatalogItemVariantUpdateRequest request}) async {
    final response = await _dio.patch(
      '/business/$businessId/catalog-item/$itemId/variants/$variantId',
      data: request.toJson(),
    );
    return CatalogItemVariantDetailResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<CatalogItemVariantSummaryResponse>> reorderVariants({required int businessId, required int itemId, required List<int> orderedVariantIds}) async {
    final variantOrders = [];
    for (int i = 0; i < orderedVariantIds.length; i++) {
      variantOrders.add({'variantId': orderedVariantIds[i], 'orderIndex': i});
    }

    final response = await _dio.patch(
      '/business/$businessId/catalog-item/$itemId/variants/reorder',
      data: {'variantOrders': variantOrders},
    );
    final dataList = response.data is List ? response.data : (response.data['data'] ?? []);
    return (dataList as List).map((x) => CatalogItemVariantSummaryResponse.fromJson(x as Map<String, dynamic>)).toList();
  }

  Future<void> activateVariant({required int businessId, required int itemId, required int variantId}) async {
    await _dio.patch('/business/$businessId/catalog-item/$itemId/variants/$variantId/activate');
  }

  Future<void> deactivateVariant({required int businessId, required int itemId, required int variantId}) async {
    await _dio.patch('/business/$businessId/catalog-item/$itemId/variants/$variantId/deactivate');
  }

  Future<void> deleteVariant({required int businessId, required int itemId, required int variantId}) async {
    await _dio.delete('/business/$businessId/catalog-item/$itemId/variants/$variantId');
  }

  // Assumed restore endpoint for variants
  Future<void> restoreVariant({required int businessId, required int itemId, required int variantId}) async {
    await _dio.patch('/business/$businessId/catalog-item/$itemId/variants/$variantId/restore');
  }
}

final catalogItemRepositoryProvider = Provider<CatalogItemRepository>((ref) {
  return CatalogItemRepository(ref.watch(dioProvider));
});
