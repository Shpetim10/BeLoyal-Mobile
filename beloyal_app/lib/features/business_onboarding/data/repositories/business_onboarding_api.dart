import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../models/business_registration_dto.dart';
import '../models/register_user_dto.dart';
import '../models/submit_application_models.dart';
import '../models/verify_ownership_models.dart';

/// API endpoints for business onboarding flow.
/// Adjust these paths if your backend uses different routes.
class BusinessOnboardingEndpoints {
  static const verifyOwnership = '/auth/verify-ownership';
  static const submitApplication = '/auth/register-business';
  static const getMyBusiness = '/business/me';
  static String getBusinessStatus(int id) => '/staff/$id/status';
  static String getApplication(int businessId) =>
      '/business/$businessId/application';
  static String updateApplication(int businessId) =>
      '/business/$businessId/application';
}

/// API client for business onboarding operations.
class BusinessOnboardingApi {
  BusinessOnboardingApi(this._dio);

  final Dio _dio;

  /// POST /besahub/auth/verify-ownership
  /// Verifies existing account ownership via email + password.
  Future<VerifyOwnershipResponse> verifyOwnership({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        BusinessOnboardingEndpoints.verifyOwnership,
        data: VerifyOwnershipRequest(email: email, password: password).toJson(),
      );

      return VerifyOwnershipResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // Re-throw with better error message
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// POST /onboarding/business/applications
  /// Submits business registration application (combined call).
  Future<SubmitBusinessApplicationResponse> submitBusinessApplication({
    required BusinessRegistrationDto businessRegistrationDto,
    required OwnerMode ownerMode,
    String? ownershipToken,
    RegisterUserDto? userDto,
  }) async {
    try {
      final response = await _dio.post(
        BusinessOnboardingEndpoints.submitApplication,
        data: SubmitBusinessApplicationRequest(
          businessRegistrationDto: businessRegistrationDto,
          ownerMode: ownerMode,
          ownershipToken: ownershipToken,
          userDto: userDto,
        ).toJson(),
      );

      return SubmitBusinessApplicationResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      // Re-throw with better error message, preserving field errors if available
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// GET /staff/{businessId}/status
  /// Fetches specific business status.
  Future<Map<String, dynamic>> getBusinessStatus(int businessId) async {
    try {
      final response = await _dio.get(
        BusinessOnboardingEndpoints.getBusinessStatus(businessId),
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// GET /business/{businessId}/application
  /// Fetches current registration data for a rejected/pending business.
  Future<BusinessRegistrationDto> getApplication(int businessId) async {
    try {
      final response = await _dio.get(
        BusinessOnboardingEndpoints.getApplication(businessId),
      );
      final data = response.data as Map<String, dynamic>;
      return BusinessRegistrationDto(
        businessName: data['businessName'] as String? ?? '',
        businessType: data['businessType'] as String? ?? 'OTHER',
        currency:
            data['currency'] as String? ??
            data['currencyCode'] as String? ??
            'ALL',
        address: data['address'] as String?,
        city: data['city'] as String? ?? '',
        country: data['country'] as String?,
        businessEmail: data['businessEmail'] as String? ?? '',
        businessPhoneNumber: data['businessPhoneNumber'] as String? ?? '',
        vatId: data['vatId'] as String?,
        websiteUrl: data['websiteUrl'] as String?,
        logoUrl: data['logoUrl'] as String?,
        logoKey: data['logoKey'] as String?,
        businessDescription: data['businessDescription'] as String?,
      );
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// PATCH /business/{businessId}/application
  /// Updates registration data for a rejected business and re-submits for review.
  Future<SubmitBusinessApplicationResponse> updateBusinessRegistration(
    int businessId,
    BusinessRegistrationDto dto,
  ) async {
    try {
      final response = await _dio.patch(
        BusinessOnboardingEndpoints.updateApplication(businessId),
        data: dto.toJson(),
      );
      // Backend wraps the payload in { "message": { ...response fields } }
      final wrapper = response.data as Map<String, dynamic>;
      final inner = wrapper['message'] as Map<String, dynamic>? ?? wrapper;
      return SubmitBusinessApplicationResponse.fromJson(inner);
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// GET /business/me
  /// Fetches current user's business information including status.
  Future<Map<String, dynamic>> getMyBusiness() async {
    try {
      final response = await _dio.get(
        BusinessOnboardingEndpoints.getMyBusiness,
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final errorMsg = _extractErrorMessage(e);
      throw Exception(errorMsg);
    }
  }

  /// Extract error message from DioException, handling various response formats.
  String _extractErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) {
      try {
        // Try to parse as JSON
        final jsonData = jsonDecode(data);
        if (jsonData is Map<String, dynamic> &&
            jsonData.containsKey('message')) {
          return jsonData['message'].toString();
        }
      } catch (_) {
        // Not JSON, return as-is
        return data;
      }
    }
    if (data is Map<String, dynamic>) {
      // First try standard keys
      final standardMsg = data['message'] ?? data['error'];
      if (standardMsg != null) return standardMsg.toString();

      // Robust fallback: Find ANY string value in the map
      for (final value in data.values) {
        if (value is String && value.isNotEmpty) return value;
      }

      return 'Something went wrong';
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        'Connection timed out. Check your network.',
      DioExceptionType.connectionError =>
        'Cannot reach server. Is the backend running?',
      _ => e.message ?? 'Network error',
    };
  }
}

/// Riverpod provider for BusinessOnboardingApi instance.
final businessOnboardingApiProvider = Provider<BusinessOnboardingApi>((ref) {
  final dio = ref.watch(dioProvider);
  return BusinessOnboardingApi(dio);
});
