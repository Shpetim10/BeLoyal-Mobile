import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/user_profile.dart';
import '../domain/customer_profile.dart';
import '../domain/staff_membership.dart';

class ProfileRepository {
  ProfileRepository(this._dio);
  final Dio _dio;

  // ── User Profile ──

  Future<AuthResult<UserProfile>> fetchUserProfile() async {
    try {
      final response = await _dio.get('/user-profile/me');
      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(UserProfile.fromJson(data));
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  Future<AuthResult<UserProfile>> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    String? profileImageKey,
    bool clearPhoneNumber = false,
    bool clearProfileImageUrl = false,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (firstName != null) data['firstName'] = firstName.trim();
      if (lastName != null) data['lastName'] = lastName.trim();
      if (username != null) data['username'] = username.trim();

      if (clearPhoneNumber) {
        data['phoneNumber'] = null;
      } else if (phoneNumber != null) {
        data['phoneNumber'] = phoneNumber.trim();
      }

      if (clearProfileImageUrl) {
        data['imagePath'] = null;
        data['imageKey'] = null;
      } else if (profileImageUrl != null && profileImageKey != null) {
        data['imagePath'] = profileImageUrl;
        data['imageKey'] = profileImageKey;
      }

      await _dio.patch('/user-profile/me', data: data);

      // Re fetch updated User Profile
      return fetchUserProfile();
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ── Customer Profile ──

  Future<AuthResult<CustomerProfile>> fetchCustomerProfile() async {
    try {
      final response = await _dio.get('/customer/me');
      if (response.statusCode == 204 ||
          response.data == null ||
          response.data.toString().isEmpty) {
        // Handle empty response for a customer without a profile
        return const AuthSuccess(CustomerProfile());
      }
      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(CustomerProfile.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        // Customer profile not found
        return const AuthSuccess(CustomerProfile());
      }
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  Future<AuthResult<CustomerProfile>> updateCustomerProfile({
    String? city,
    String? country,
    String? gender,
    DateTime? birthdate,
    bool clearCity = false,
    bool clearCountry = false,
    bool clearGender = false,
    bool clearBirthdate = false,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (clearCity) {
        data['city'] = null;
      } else if (city != null) {
        data['city'] = city.trim();
      }

      if (clearCountry) {
        data['country'] = null;
      } else if (country != null) {
        data['country'] = country.trim();
      }

      if (clearGender) {
        data['gender'] = null;
      } else if (gender != null) {
        data['gender'] = gender;
      }

      if (clearBirthdate) {
        data['birthDate'] = null;
      } else if (birthdate != null) {
        // Send as YYYY-MM-DD string
        final monthStr = birthdate.month.toString().padLeft(2, '0');
        final dayStr = birthdate.day.toString().padLeft(2, '0');
        data['birthDate'] = '${birthdate.year}-$monthStr-$dayStr';
      }

      await _dio.patch('/customer/me', data: data);

      // Re-fetch to guarantee fully populated data
      return fetchCustomerProfile();
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ── Security ──

  Future<AuthResult<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {'currentPassword': currentPassword, 'newPassword': newPassword},
      );

      final msg =
          response.data?['message']?.toString() ??
          'Password updated successfully';
      return AuthSuccess(msg);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ── Staff Membership ──

  Future<AuthResult<StaffMembership>> fetchStaffMembership(
    int businessId,
  ) async {
    try {
      final response = await _dio.get('/business-member/me/$businessId');
      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(StaffMembership.fromJson(data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const AuthError(AuthFailure('Membership not found.'));
      }
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── Error mapping ──────────────
  AuthFailure _mapDioError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final msg = data['message'] as String? ?? 'Something went wrong';
      final fieldErrors = <String, String>{};
      if (data.containsKey('fieldErrors') && data['fieldErrors'] is Map) {
        (data['fieldErrors'] as Map).forEach((k, v) {
          fieldErrors[k.toString()] = v.toString();
        });
      }
      return AuthFailure(msg, fieldErrors: fieldErrors);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        const AuthFailure('Connection timed out. Check your network.'),
      DioExceptionType.connectionError => const AuthFailure(
        'Cannot reach server. Is the backend running?',
      ),
      _ => AuthFailure(e.message ?? 'Network error'),
    };
  }
}

/// Riverpod provider for ProfileRepository.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});
