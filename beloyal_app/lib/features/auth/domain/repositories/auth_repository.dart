import '../models/auth_user.dart';
import '../models/customer_profile_creation_response.dart';

/// Domain-level failure wrapper.
class AuthFailure {
  const AuthFailure(this.message, {this.fieldErrors, this.errorCode});

  final String message;
  final Map<String, String>? fieldErrors;
  final String? errorCode;
}

/// Sealed result type for auth operations.
sealed class AuthResult<T> {
  const AuthResult();
}

class AuthSuccess<T> extends AuthResult<T> {
  const AuthSuccess(this.data);
  final T data;
}

class AuthError<T> extends AuthResult<T> {
  const AuthError(this.failure);
  final AuthFailure failure;
}

/// Contract for authentication data source — swappable between real API / mock.
abstract class AuthRepository {
  /// POST /auth/login
  Future<AuthResult<AuthUser>> login({
    required String email,
    required String password,
  });

  /// POST /auth/register
  Future<AuthResult<String>> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    String? phoneNumber,
    required bool acceptedTc,
    required String acceptedTcVersion,
  });

  /// POST /customer/me/create-profile
  Future<AuthResult<CustomerProfileCreationResponse>> createCustomerProfile({
    required String token,
    DateTime? birthdate,
    String? gender,
    String? city,
    String? country,
    String? referredBy,
    String? profileImageUrl,
    String? profileImageKey,
    bool notificationEnabled = true,
  });

  /// Verify email with token (from deep link).
  Future<AuthResult<AuthUser>> verifyEmail(String token);

  /// POST /auth/forget-password
  Future<AuthResult<String>> forgetPassword({required String email});

  /// POST /auth/change-password
  Future<AuthResult<String>> resetPassword({
    required String token,
    required String newPassword,
  });

  /// Resend verification email
  Future<AuthResult<String>> resendVerification(String email);

  /// POST /auth/refresh — exchange refresh token for new tokens (and optionally rotated refresh).
  Future<AuthResult<AuthUser>> refresh(
    String refreshToken, {
    String? accessToken,
  });

  /// POST /auth/logout — best-effort revoke of refresh token on backend.
  Future<void> logout(String refreshToken);
}
