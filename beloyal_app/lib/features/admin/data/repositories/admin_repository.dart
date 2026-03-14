import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../domain/models/business_application.dart';

class AdminRepository {
  AdminRepository(this._dio);

  final Dio _dio;

  /// Fetches pending business applications.
  /// Note: Real API might have pagination or specific status filters.
  /// We'll assume GET /business-applications returns pending applications or
  /// we can pass an explicit query param to fetch them.
  Future<List<BusinessApplication>> fetchPendingApplications() async {
    try {
      final response = await _dio.get('/admin/business-applications');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => BusinessApplication.fromJson(e as Map<String, dynamic>))
            // Filter locally just in case the endpoint returns everything
            .where(
              (app) =>
                  app.businessStatus.value == 'PENDING_APPROVAL' ||
                  app.businessStatus.name.toLowerCase().contains('pending'),
            )
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Approve a business registration
  Future<void> approveApplication(int businessId) async {
    try {
      await _dio.post('/admin/business-applications/$businessId/approve');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Reject a business registration
  Future<void> rejectApplication(int businessId, String reason) async {
    try {
      await _dio.post(
        '/admin/business-applications/$businessId/reject',
        data: {'rejectionReason': reason},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      return Exception(
        errorData['message'] as String? ?? 'An admin error occurred',
      );
    }
    return Exception(e.message ?? 'Network error');
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminRepository(dio);
});
