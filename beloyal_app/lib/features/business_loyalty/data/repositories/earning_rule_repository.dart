import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

class EarningRuleRepository {
  EarningRuleRepository(this._dio);
  final Dio _dio;

  Future<void> patchEarningSettings({
    required int businessId,
    required int amountPer,
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
