import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/admin_business_dtos.dart';

class AdminBusinessRepository {
  AdminBusinessRepository(this._dio);

  final Dio _dio;

  /// Fetches all businesses registered in the app (Superadmin only).
  Future<List<BusinessListViewDto>> getAllBusinesses() async {
    try {
      final response = await _dio.get('/admin/businesses');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => BusinessListViewDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetches the complete extended details of a specific business.
  Future<BusinessDetailsDto> getBusinessDetails(int businessId) async {
    try {
      final response = await _dio.get('/admin/businesses/$businessId');
      return BusinessDetailsDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Suspends a business (ACTIVE → INACTIVE).
  Future<void> suspendBusiness(int businessId, String reason) async {
    try {
      await _dio.patch(
        '/admin/businesses/$businessId/suspend',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Bans a business (any status → BANNED).
  Future<void> banBusiness(int businessId, String reason) async {
    try {
      await _dio.patch(
        '/admin/businesses/$businessId/ban',
        data: {'reason': reason},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Reactivates a business (INACTIVE/BANNED → ACTIVE).
  Future<void> reactivateBusiness(int businessId) async {
    try {
      await _dio.patch('/admin/businesses/$businessId/reactivate');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Hard deletes a business and all associated data.
  Future<void> deleteBusiness(int businessId) async {
    try {
      await _dio.delete('/admin/businesses/$businessId');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetches all platform users with roles, memberships, and loyalty metrics.
  Future<List<PlatformUserSummaryDto>> getPlatformUsers() async {
    try {
      final response = await _dio.get('/admin/platform/users');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) =>
                PlatformUserSummaryDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      final message = errorData['message'];
      String displayMessage = 'An error occurred fetching business data';

      if (message is String) {
        displayMessage = message;
      } else if (message is Iterable) {
        displayMessage = message.join(', ');
      } else if (message != null) {
        displayMessage = message.toString();
      }

      return Exception(displayMessage);
    }
    return Exception(e.message ?? 'Network error');
  }
}

final adminBusinessRepositoryProvider = Provider<AdminBusinessRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminBusinessRepository(dio);
});
