import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class EarningRuleRepository {
  EarningRuleRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> getEarningSettings({
    required int businessId,
  }) async {
    final response = await _dio.get('/business/$businessId/earning-settings');
    return response.data as Map<String, dynamic>;
  }

  Future<void> patchEarningSettings({
    required int businessId,
    required double amountPer,
    required int pointsPer,
  }) async {
    await _dio.patch(
      '/business/$businessId/earning-settings',
      data: {'amountPer': amountPer, 'pointsPer': pointsPer},
    );
  }
}

final earningRuleRepositoryProvider = Provider<EarningRuleRepository>((ref) {
  return EarningRuleRepository(ref.watch(dioProvider));
});
