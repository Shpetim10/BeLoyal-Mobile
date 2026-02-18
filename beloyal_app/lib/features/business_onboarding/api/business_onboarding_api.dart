import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
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
      return data['message'] as String? ??
          data['error'] as String? ??
          'Something went wrong';
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
