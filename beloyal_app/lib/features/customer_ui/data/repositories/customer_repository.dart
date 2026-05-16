import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:besahub_app/core/network/api_client.dart';
import '../models/customer_home_dto.dart';
export '../models/customer_home_dto.dart'
    show CustomerCouponRedemptionDto, ValidateRedemptionDto;

class CustomerRepository {
  const CustomerRepository(this._dio);
  final Dio _dio;

  Future<CustomerHomeDto> fetchHome() async {
    final response = await _dio.get('/customer/home');
    return CustomerHomeDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomerBusinessDetailDto> fetchBusinessDetail(int businessId) async {
    final response = await _dio.get('/customer/businesses/$businessId');
    return CustomerBusinessDetailDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CustomerProfileDetailsDto> fetchProfileDetails() async {
    final response = await _dio.get('/customer/me/details');
    return CustomerProfileDetailsDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    required String country,
    required String? gender,
    required DateTime? birthDate,
    bool? notificationEnabled,
  }) async {
    await _dio.patch(
      '/user-profile/me',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'phoneNumber': phone.isEmpty ? null : phone,
      },
    );

    final customerPayload = <String, dynamic>{
      'city': city.isEmpty ? null : city,
      'country': country.isEmpty ? null : country,
      'gender': gender,
      'birthDate': birthDate == null
          ? null
          : '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
    };
    if (notificationEnabled != null) {
      customerPayload['notificationEnabled'] = notificationEnabled;
    }
    await _dio.patch('/customer/me', data: customerPayload);
  }

  Future<void> updateNotificationEnabled(bool enabled) async {
    await _dio.patch('/customer/me', data: {'notificationEnabled': enabled});
  }

  // NOTE: /customer/my-coupons, /customer/home promotions, and
  // /customer/businesses/{id} coupons all return plain List<> arrays.
  // Pagination is not yet implemented on the backend; these endpoints return
  // the full result set. When pagination is added, a cursor/page parameter will
  // be introduced and these callers will need to be updated.
  Future<List<CustomerPromotionDto>> fetchMyCoupons() async {
    final response = await _dio.get('/customer/my-coupons');
    final list = response.data as List? ?? [];
    return list
        .map((e) => CustomerPromotionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ValidateRedemptionDto> validateRedemption(int couponId) async {
    final response = await _dio.post(
      '/customer/coupons/$couponId/validate-redemption',
    );
    return ValidateRedemptionDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CustomerCouponRedemptionDto> redeemCoupon(int couponId) async {
    final response = await _dio.post('/customer/coupons/$couponId/redeem');
    return CustomerCouponRedemptionDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<CustomerPromotionDto> fetchCouponDetails(int couponId) async {
    final response = await _dio.get('/customer/coupons/$couponId');
    return CustomerPromotionDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomerPromotionDto> fetchCustomerCouponById(
    int customerCouponId,
  ) async {
    final response = await _dio.get(
      '/customer/customer-coupons/$customerCouponId',
    );
    return CustomerPromotionDto.fromJson(response.data as Map<String, dynamic>);
  }
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(dioProvider));
});
