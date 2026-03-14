import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/loyalty_card_dto.dart';

/// Fetches the authenticated customer's loyalty card from the backend.
class LoyaltyCardRepository {
  LoyaltyCardRepository(this._dio);
  final Dio _dio;

  Future<LoyaltyCardDto> fetchMyCard() async {
    final response = await _dio.get('/customer/me/loyalty-card');
    final data = response.data as Map<String, dynamic>;
    return LoyaltyCardDto.fromJson(data);
  }
}

final loyaltyCardRepositoryProvider = Provider<LoyaltyCardRepository>((ref) {
  return LoyaltyCardRepository(ref.watch(dioProvider));
});
