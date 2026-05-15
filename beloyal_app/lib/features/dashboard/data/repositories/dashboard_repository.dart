import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../models/dashboard_summary_dtos.dart';

class DashboardRepository {
  DashboardRepository(this._dio);

  final Dio _dio;

  /// GET /business/{id}/dashboard-summary — BUSINESS_ADMIN only.
  Future<BusinessDashboardSummaryDto> fetchBusinessSummary(int businessId) async {
    try {
      final response = await _dio.get('/business/$businessId/dashboard-summary');
      return BusinessDashboardSummaryDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /business/{id}/staff-summary — STAFF only.
  Future<StaffDashboardSummaryDto> fetchStaffSummary(int businessId) async {
    try {
      final response = await _dio.get('/business/$businessId/staff-summary');
      return StaffDashboardSummaryDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// GET /admin/platform-summary — SUPER_ADMIN only.
  Future<AdminPlatformSummaryDto> fetchPlatformSummary() async {
    try {
      final response = await _dio.get('/admin/platform-summary');
      return AdminPlatformSummaryDto.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final msg = (e.response!.data as Map<String, dynamic>)['message'];
      if (msg is String) return Exception(msg);
      if (msg is Iterable) return Exception(msg.join(', '));
      if (msg != null) return Exception(msg.toString());
    }
    return Exception(e.message ?? 'Network error');
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});
