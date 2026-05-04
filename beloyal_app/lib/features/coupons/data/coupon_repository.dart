import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import 'models/coupon_create_request.dart';
import 'models/coupon_detail.dart';
import 'models/coupon_enums.dart';
import 'models/coupon_lookup_models.dart';
import 'models/coupon_summary.dart';

class CouponRepository {
  CouponRepository(this._dio);

  final Dio _dio;

  String _base(int businessId) => '/business/$businessId';

  // ── Image Upload ──────────────────────────────────────────────────────────

  Future<CouponImageUploadResponse> uploadCouponImage({
    required int businessId,
    required XFile file,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _dio.post(
      '${_base(businessId)}/media/coupon-images',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return CouponImageUploadResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ── Lookups ───────────────────────────────────────────────────────────────

  Future<List<CategoryLookup>> lookupCategories({
    required int businessId,
  }) async {
    final response = await _dio.get('${_base(businessId)}/lookups/categories');
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => CategoryLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductLookup>> lookupProducts({
    required int businessId,
    required int categoryId,
  }) async {
    final response = await _dio.get(
      '${_base(businessId)}/lookups/products',
      queryParameters: {'categoryId': categoryId},
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => ProductLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<VariantLookup>> lookupVariants({
    required int businessId,
    required int productId,
  }) async {
    final response = await _dio.get(
      '${_base(businessId)}/lookups/products/$productId/variants',
    );
    final data = response.data as Map<String, dynamic>;
    final list = data['data'] as List<dynamic>? ?? [];
    return list
        .map((e) => VariantLookup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  Future<CouponDetail> createCoupon({
    required int businessId,
    required CouponCreateRequest request,
  }) async {
    final response = await _dio.post(
      '${_base(businessId)}/coupons',
      data: request.toJson(),
    );
    return CouponDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CouponPage> listCoupons({
    required int businessId,
    CouponStatus? status,
    CouponType? type,
    String? search,
    int page = 0,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortDirection = 'DESC',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };
    if (status != null) params['status'] = status.backendValue;
    if (type != null) params['type'] = type.backendValue;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _dio.get(
      '${_base(businessId)}/coupons',
      queryParameters: params,
    );
    return CouponPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CouponDetail> getCoupon({
    required int businessId,
    required int couponId,
  }) async {
    final response = await _dio.get('${_base(businessId)}/coupons/$couponId');
    return CouponDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CouponDetail> updateCoupon({
    required int businessId,
    required int couponId,
    required Map<String, dynamic> updates,
  }) async {
    final response = await _dio.patch(
      '${_base(businessId)}/coupons/$couponId',
      data: updates,
    );
    return CouponDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changeCouponStatus({
    required int businessId,
    required int couponId,
    required CouponStatus status,
  }) async {
    await _dio.patch(
      '${_base(businessId)}/coupons/$couponId/status',
      data: {'status': status.backendValue},
    );
  }

  Future<void> archiveCoupon({
    required int businessId,
    required int couponId,
  }) async {
    await _dio.patch('${_base(businessId)}/coupons/$couponId/archive');
  }

  Future<void> deleteCoupon({
    required int businessId,
    required int couponId,
  }) async {
    await _dio.delete('${_base(businessId)}/coupons/$couponId');
  }

  // ── Archived / Expired / Trash lists ─────────────────────────────────────

  Future<CouponPage> listArchivedCoupons({
    required int businessId,
    CouponType? type,
    String? search,
    int page = 0,
    int limit = 20,
    String sortBy = 'archivedAt',
    String sortDirection = 'DESC',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };
    if (type != null) params['type'] = type.backendValue;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _dio.get(
      '${_base(businessId)}/coupons/archived',
      queryParameters: params,
    );
    return CouponPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CouponPage> listTrashedCoupons({
    required int businessId,
    CouponType? type,
    String? search,
    int page = 0,
    int limit = 20,
    String sortBy = 'createdAt',
    String sortDirection = 'DESC',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };
    if (type != null) params['type'] = type.backendValue;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _dio.get(
      '${_base(businessId)}/coupons/trash',
      queryParameters: params,
    );
    return CouponPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CouponPage> listExpiredCoupons({
    required int businessId,
    CouponType? type,
    String? search,
    int page = 0,
    int limit = 20,
    String sortBy = 'endDate',
    String sortDirection = 'DESC',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sortBy': sortBy,
      'sortDirection': sortDirection,
    };
    if (type != null) params['type'] = type.backendValue;
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await _dio.get(
      '${_base(businessId)}/coupons/expired',
      queryParameters: params,
    );
    return CouponPage.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Lifecycle actions ─────────────────────────────────────────────────────

  Future<void> restoreFromArchive({
    required int businessId,
    required int couponId,
  }) async {
    await _dio.patch('${_base(businessId)}/coupons/$couponId/restore-archive');
  }

  Future<void> reviveCoupon({
    required int businessId,
    required int couponId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _dio.patch(
      '${_base(businessId)}/coupons/$couponId/revive',
      data: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
  }

  Future<void> restoreFromTrash({
    required int businessId,
    required int couponId,
  }) async {
    await _dio.patch('${_base(businessId)}/coupons/trash/$couponId/restore');
  }
}

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return CouponRepository(ref.watch(dioProvider));
});
