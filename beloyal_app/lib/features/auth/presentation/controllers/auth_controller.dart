import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/auth_repository_impl.dart';
import '../../../../core/services/token_storage.dart';
import 'session_controller.dart';

/// Set to false to disable auth debug logs.
bool get kAuthDebugLog => kDebugMode;

void _authLog(String message) {
  if (kAuthDebugLog) debugPrint('🔐 Auth: $message');
}

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref);
});

final authStartupProvider = FutureProvider<void>((ref) async {
  await ref.read(authControllerProvider).tryAutoLogin();
});

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<AuthResult<AuthUser>> login(String email, String password) async {
    _authLog('Login attempt for $email');
    final repo = ref.read(authRepositoryProvider);
    final storage = ref.read(tokenStorageProvider);

    final result = await repo.login(
      email: email.trim().toLowerCase(),
      password: password,
    );

    switch (result) {
      case AuthSuccess(data: final user):
        if (user.token.isEmpty || user.refreshToken.isEmpty) {
          _authLog('Login failed: response missing access or refresh token');
          return AuthError(AuthFailure('Invalid login response'));
        }
        await storage.saveTokens(
          accessToken: user.token,
          refreshToken: user.refreshToken,
        );
        _authLog('Login success; tokens saved, setting session');
        await ref.read(sessionControllerProvider.notifier).setSession(user);
        return AuthSuccess(user);
      case AuthError(failure: final f):
        _authLog('Login failed: ${f.message}');
        return AuthError(f);
    }
  }

  /// App startup: try to restore session using refresh token.
  Future<bool> tryAutoLogin() async {
    _authLog('tryAutoLogin: checking refresh token...');
    final storage = ref.read(tokenStorageProvider);
    final refresh = await storage.getRefreshToken();

    if (refresh == null || refresh.isEmpty) {
      _authLog('tryAutoLogin: no refresh token');
      return false;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.refresh(refresh);

      switch (result) {
        case AuthSuccess(data: final user):
          if (user.token.isEmpty) {
            _authLog('tryAutoLogin: refresh response missing access token');
            await storage.clear();
            ref.read(sessionControllerProvider.notifier).logout();
            return false;
          }
          await storage.saveTokens(
            accessToken: user.token,
            refreshToken: user.refreshToken.isNotEmpty
                ? user.refreshToken
                : refresh,
          );
          _authLog('tryAutoLogin: success; session restored');
          await ref.read(sessionControllerProvider.notifier).setSession(user);
          return true;
        case AuthError(failure: final f):
          _authLog('tryAutoLogin: refresh failed - ${f.message}');
          await storage.clear();
          ref.read(sessionControllerProvider.notifier).logout();
          return false;
      }
    } catch (e) {
      _authLog('tryAutoLogin: error - $e');
      await storage.clear();
      ref.read(sessionControllerProvider.notifier).logout();
      return false;
    }
  }

  /// Logout: best-effort revoke on backend when refresh token exists, then always clear local state.
  Future<void> logout() async {
    _authLog('Logout');
    final repo = ref.read(authRepositoryProvider);
    final storage = ref.read(tokenStorageProvider);
    final refresh = await storage.getRefreshToken();

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await repo.logout(refresh);
        debugPrint('🔐 Auth: Logout: backend revoke succeeded');
      } on DioException catch (e) {
        debugPrint('🔐 Auth: Logout: backend revoke failed: '
            '${e.response?.statusCode} ${e.response?.data}');
      } catch (e) {
        debugPrint('🔐 Auth: Logout: backend revoke failed: $e');
      }
    }

    await storage.clear();
    ref.read(sessionControllerProvider.notifier).logout();
  }
}
