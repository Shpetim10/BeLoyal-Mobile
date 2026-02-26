import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../auth/domain/repositories/auth_repository.dart';

/// Repository for handling staff invitation acceptance flows.
class StaffInvitationRepository {
  StaffInvitationRepository(this._dio);
  final Dio _dio;

  /// Registers a NEW user via a staff invitation token.
  /// POST /staff/invitations/register
  Future<AuthResult<String>> registerNewStaffMember({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    String? phoneNumber,
    required String password,
    required bool acceptedTc,
    required String acceptedTcVersion,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/staff/invitations/register',
        data: {
          'token': token,
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'email': email.trim().toLowerCase(),
          'username': username.trim(),
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber.trim(),
          'password': password,
          'acceptedTc': acceptedTc,
          'acceptedTcVersion': acceptedTcVersion,
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final message =
          data?['message']?.toString() ??
          'Invitation accepted. Account created.';
      return AuthSuccess(message);
    } on DioException catch (e) {
      return AuthError(_mapDioError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  /// Accepts an invitation for an EXISTING logged-in user.
  /// POST /staff/invitations/accept
  Future<AuthResult<String>> acceptInvitationAsExistingUser({
    required String token,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/staff/invitations/accept',
        data: {'token': token},
      );

      final data = response.data as Map<String, dynamic>?;
      final message = data?['message']?.toString() ?? 'Invitation accepted.';
      return AuthSuccess(message);
    } on DioException catch (e) {
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

/// Riverpod provider for StaffInvitationRepository.
final staffInvitationRepositoryProvider = Provider<StaffInvitationRepository>((
  ref,
) {
  return StaffInvitationRepository(ref.watch(dioProvider));
});
