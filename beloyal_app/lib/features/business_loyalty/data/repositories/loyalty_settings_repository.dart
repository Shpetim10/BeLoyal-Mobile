import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/loyalty_settings_dto.dart';

class LoyaltySettingsRepository {
  LoyaltySettingsRepository(this._dio);
  final Dio _dio;

  Future<LoyaltySettingsDto> fetchLoyaltySettings({
    required int businessId,
  }) async {
    final response = await _dio.get('/business/$businessId/loyalty-settings');
    final data = response.data as Map<String, dynamic>;
    return LoyaltySettingsDto.fromJson(data);
  }

  Future<void> patchLoyaltySettings({
    required int businessId,
    required LoyaltySettingsDto dto,
  }) async {
    await _dio.patch(
      '/business/$businessId/loyalty-settings',
      data: dto.toJson(),
    );
  }
}

final loyaltySettingsRepositoryProvider = Provider<LoyaltySettingsRepository>((
  ref,
) {
  return LoyaltySettingsRepository(ref.watch(dioProvider));
});
