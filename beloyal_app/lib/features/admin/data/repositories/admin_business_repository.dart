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
