import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:besahub_app/core/network/api_client.dart';
import '../models/customer_home_dto.dart';

class CustomerRepository {
  const CustomerRepository(this._dio);
  final Dio _dio;

  Future<CustomerHomeDto> fetchHome() async {
    final response = await _dio.get('/customer/home');
    return CustomerHomeDto.fromJson(response.data as Map<String, dynamic>);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(dioProvider));
});
