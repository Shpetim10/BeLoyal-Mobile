import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/entities/auth_user.dart';
import '../domain/repositories/auth_repository.dart';

/// Real implementation hitting Spring Boot at /api/beloyal/...
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dio);
  final Dio _dio;

  // ────────────── LOGIN ──────────────
  @override
  Future<AuthResult<AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email.trim().toLowerCase(), 'password': password},
        options: Options(responseType: ResponseType.plain),
      );

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.data.toString());
      } catch (e) {
        throw FormatException('Invalid JSON response: ${response.data}');
      }

      final data = decoded as Map<String, dynamic>;

      return AuthSuccess(_authUserFromMap(data, data));
    } on DioException catch (e) {
      // If response data is plain text error, use it.
      if (e.response != null && e.response?.data is String) {
        // Try to parse as JSON error, else use raw string
        try {
          final errMap = jsonDecode(e.response!.data as String);
          if (errMap is Map && errMap.containsKey('message')) {
            return AuthError(AuthFailure(errMap['message'].toString()));
          }
        } catch (_) {}
        // fallback to raw string
        return AuthError(AuthFailure(e.response!.data.toString()));
      }
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── REGISTER ──────────────
  @override
  Future<AuthResult<String>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    String? phoneNumber,
    required bool acceptedTc,
    required String acceptedTcVersion,
  }) async {
    try {
      // Spring Boot returns Content-Type: text/plain for this endpoint.
      // We must use ResponseType.plain so Dio doesn't try to JSON-decode
      // the plain-text body (which would throw a FormatException).
      final response = await _dio.post(
        '/auth/register',
        data: {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'password': password,
          'username': username.trim(),
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber.trim(),
          'acceptedTc': acceptedTc,
          'acceptedTcVersion': acceptedTcVersion,
        },
        options: Options(responseType: ResponseType.plain),
      );

      final message = (response.data?.toString().isNotEmpty ?? false)
          ? response.data.toString()
          : 'Registration successful';
      return AuthSuccess(message);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── CREATE PROFILE ──────────────
  @override
  Future<AuthResult<String>> createCustomerProfile({
    required String token,
    DateTime? birthdate,
    String? gender,
    String? city,
    String? country,
    String? referredBy,
    String? profileImageUrl,
    String? profileImageKey,
    bool notificationEnabled = true,
  }) async {
    try {
      final response = await _dio.post(
        '/customer/me/create-profile',
        data: {
          if (birthdate != null)
            'birthdate': birthdate.toIso8601String().split('T').first,
          if (gender != null) 'gender': gender,
          if (city != null) 'city': city,
          if (country != null) 'country': country,
          if (referredBy != null && referredBy.isNotEmpty)
            'referredBy': referredBy,
          if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
          if (profileImageKey != null) 'profileImageKey': profileImageKey,
          'notificationEnabled': notificationEnabled,
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          responseType: ResponseType
              .plain, // Handle plain text "Customer profile created successfully!"
        ),
      );

      final message = response.data?.toString() ?? 'Profile created';
      return AuthSuccess(message);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── VERIFY EMAIL ──────────────
  @override
  Future<AuthResult<AuthUser>> verifyEmail(String token) async {
    try {
      final response = await _dio.get(
        '/auth/activate',
        queryParameters: {'token': token},
      );

      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(_authUserFromMap(data, data));
    } on DioException catch (e) {
      // Handle specific error codes
      if (e.response?.statusCode == 410) {
        // GONE - token expired
        final data = e.response?.data as Map<String, dynamic>?;
        return AuthError(
          AuthFailure(
            data?['message'] as String? ?? 'Activation link expired',
            errorCode: 'TOKEN_EXPIRED',
          ),
        );
      }

      if (e.response?.statusCode == 400) {
        // Bad request - invalid token
        final data = e.response?.data as Map<String, dynamic>?;
        return AuthError(
          AuthFailure(
            data?['message'] as String? ?? 'Invalid activation link',
            errorCode: 'INVALID_TOKEN',
          ),
        );
      }

      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── Resend Verification ──────────────
  @override
  Future<AuthResult<String>> resendVerification(String email) async {
    try {
      final response = await _dio.post(
        '/auth/resend-verification',
        data: {'email': email},
      );

      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(data['message'] as String);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── FORGET PASSWORD ──────────────
  @override
  Future<AuthResult<String>> forgetPassword({required String email}) async {
    try {
      final response = await _dio.post(
        '/auth/forget-password',
        data: {'email': email},
        // Wait for plain response as it returns ResponseEntity<Map<String, String>>
      );

      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(data['message'] as String? ?? 'Email was sent');
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── RESET PASSWORD ──────────────
  @override
  Future<AuthResult<String>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: {'token': token, 'newPassword': newPassword},
      );

      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(
        data['message'] as String? ?? 'Password has been changed',
      );
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── REFRESH ──────────────
  @override
  Future<AuthResult<AuthUser>> refresh(
    String refreshToken, {
    String? accessToken,
  }) async {
    try {
      debugPrint(
        '🔐 AuthRepo: Refreshing with accessToken present: ${accessToken != null}',
      );
      final response = await _dio.post(
        '/auth/refresh',
        data: {
          'refreshToken': refreshToken,
          if (accessToken != null) 'accessToken': accessToken,
        },
        options: Options(responseType: ResponseType.plain),
      );

      debugPrint(
        '🔐 AuthRepo: Refresh Response Status: ${response.statusCode}',
      );
      debugPrint('🔐 AuthRepo: Refresh Response Data: ${response.data}');

      final dynamic decoded;
      try {
        decoded = jsonDecode(response.data.toString());
      } catch (e) {
        debugPrint('🔐 AuthRepo: JSON Decode Error: $e');
        throw FormatException('Invalid JSON response: ${response.data}');
      }

      final data = decoded as Map<String, dynamic>;
      return AuthSuccess(_authUserFromMap(data, data));
    } on DioException catch (e) {
      debugPrint(
        '🔐 AuthRepo: Refresh DioException: ${e.response?.statusCode} ${e.response?.data}',
      );
      return AuthError(_mapDioError(e));
    } catch (e) {
      debugPrint('🔐 AuthRepo: Refresh Generic Error: $e');
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── LOGOUT ──────────────
  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (_) {
      // Best-effort: ignore so caller always clears local state
    }
  }

  /// Build AuthUser from API map (login/refresh). Tolerates token vs accessToken, missing roles.
  AuthUser _authUserFromMap(
    Map<String, dynamic> data,
    Map<String, dynamic> tokenSource,
  ) {
    final access = (tokenSource['accessToken'] ?? tokenSource['token'] ?? '')
        .toString()
        .trim();
    final refresh = (tokenSource['refreshToken'] ?? '').toString().trim();

    // Roles can be List<String> or a comma-separated String
    final dynamic rawRoles = data['roles'];
    final List<String> rolesList = [];
    if (rawRoles is List) {
      rolesList.addAll(rawRoles.map((e) => e.toString()));
    } else if (rawRoles is String && rawRoles.isNotEmpty) {
      rolesList.addAll(rawRoles.split(',').map((e) => e.trim()));
    }

    final roles = rolesList.map((r) => UserRole.fromBackend(r)).toSet();

    // Parse businessProfiles list from backend: List<Map<String, dynamic>>
    final dynamic rawBusinessProfiles = data['businessProfiles'];
    final businessProfiles = <BusinessProfileInfo>[];
    if (rawBusinessProfiles is List) {
      for (final item in rawBusinessProfiles) {
        if (item is Map) {
          final id = item['businessId'] as num?;
          final businessName = (item['businessName'] as String?) ?? 'Unknown';
          final roleStr = item['role'] as String?;

          // Robust boolean parsing
          final dynamic rawActive = item['active'];
          final active =
              rawActive == true ||
              rawActive?.toString().toLowerCase() == 'true' ||
              rawActive == 1 ||
              rawActive?.toString() == '1';

          if (id != null && roleStr != null) {
            businessProfiles.add(
              BusinessProfileInfo(
                businessId: id.toInt(),
                businessName: businessName,
                role: UserRole.fromBackend(roleStr),
                active: active,
                status: item['status'] as String?,
                rejectionReason: item['rejectionReason'] as String?,
              ),
            );
          }
        }
      }
    }

    final activeBusinessCount = businessProfiles.where((p) => p.active).length;

    final Set<UserRole> resolvedRoles = {...roles};

    // Robust boolean parsing for top-level fields
    bool parseBool(dynamic val) =>
        val == true ||
        val?.toString().toLowerCase() == 'true' ||
        val == 1 ||
        val?.toString() == '1';

    return AuthUser(
      userId: (data['userId'] as num?)?.toInt() ?? 0,
      token: access,
      tokenType: (data['tokenType'] as String?) ?? 'Bearer',
      refreshToken: refresh,
      roles: resolvedRoles,
      emailVerified: parseBool(data['emailVerified']),
      customerProfileComplete: parseBool(
        data['customerProfileComplete'] ?? data['profileComplete'],
      ),
      alreadyVerified: parseBool(data['alreadyVerified']),
      hasMultipleRoles: (resolvedRoles.length + activeBusinessCount) > 1,
      businessProfiles: businessProfiles,
    );
  }

  // ────────────── Error mapping ──────────────
  AuthFailure _mapDioError(DioException e) {
    final data = e.response?.data;
    if (data is String && data.isNotEmpty) {
      return AuthFailure(data);
    }
    if (data is Map<String, dynamic>) {
      // Support structured errors if backend evolves.
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

/// Riverpod provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(dioProvider));
});
