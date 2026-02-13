import 'package:dio/dio.dart';
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
      );

      final data = response.data as Map<String, dynamic>;
      final roles = (data['roles'] as List<dynamic>)
          .map((r) => UserRole.fromBackend(r.toString()))
          .toSet();

      return AuthSuccess(
        AuthUser(
          token: data['token'] as String,
          tokenType: (data['tokenType'] as String?) ?? 'Bearer',
          roles: roles,
          emailVerified: (data['emailVerified'] as bool?) ?? false,
          profileComplete: (data['profileComplete'] as bool?) ?? false,
        ),
      );
    } on DioException catch (e) {
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
          'notificationEnabled': notificationEnabled,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final message = response.data is String
          ? response.data as String
          : 'Profile created';
      return AuthSuccess(message);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ────────────── VERIFY EMAIL ──────────────
  @override
  Future<AuthResult<String>> verifyEmail(String token) async {
    try {
      // Prefer POST /auth/verify-email
      final response = await _dio.post(
        '/auth/verify-email',
        queryParameters: {'token': token},
      );
      return AuthSuccess(_extractMessage(response.data));
    } on DioException catch (e) {
      // Fallback: If POST fails (e.g. 404 Not Found), try GET /auth/activate
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          final response = await _dio.get(
            '/auth/activate',
            queryParameters: {'token': token},
          );
          return AuthSuccess(_extractMessage(response.data));
        } catch (e2) {
          if (e2 is DioException) return AuthError(_mapDioError(e2));
          return AuthError(AuthFailure(e2.toString()));
        }
      }
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  String _extractMessage(dynamic data) {
    if (data is String) return data;
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ?? 'Email verified successfully';
    }
    return 'Email verified successfully';
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
