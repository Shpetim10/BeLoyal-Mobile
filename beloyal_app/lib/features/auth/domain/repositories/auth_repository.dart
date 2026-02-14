import '../entities/auth_user.dart';

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
  Future<AuthResult<String>> createCustomerProfile({
    required String token,
    DateTime? birthdate,
    String? gender,
    String? city,
    String? country,
    String? referredBy,
    bool notificationEnabled = true,
  });

  /// Verify email with token (from deep link).
  Future<AuthResult<AuthUser>> verifyEmail(String token);
  /// Resend verification email
  Future<AuthResult<String>> resendVerification(String email); // New method
}
