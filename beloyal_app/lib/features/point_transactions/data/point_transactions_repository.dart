import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import 'models/point_transaction_list_dto.dart';
import 'models/point_transaction_view_dto.dart';

class PointTransactionsRepository {
  PointTransactionsRepository(this._dio);

  final Dio _dio;

  /// Fetches all points transactions for a specific business.
  Future<List<PointTransactionBusinessListViewDto>> fetchTransactions(int businessId) async {
    try {
      final response = await _dio.get('/business/$businessId/transactions');
      final data = response.data;
      if (data is List) {
        return data
            .map((e) => PointTransactionBusinessListViewDto.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Fetches full details for a single points transaction.
  Future<PointTransactionViewDto> fetchTransactionDetail(int businessId, int transactionId) async {
    try {
      final response = await _dio.get('/business/$businessId/transactions/$transactionId');
      return PointTransactionViewDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Exception _mapError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map<String, dynamic>) {
      final errorData = e.response!.data as Map<String, dynamic>;
      final message = errorData['message'];
      String displayMessage = 'An error occurred fetching transactions';
      
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

final pointTransactionsRepositoryProvider = Provider<PointTransactionsRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PointTransactionsRepository(dio);
});
