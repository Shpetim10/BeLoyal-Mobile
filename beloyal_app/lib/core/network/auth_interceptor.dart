import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage.dart';
import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';
import 'api_client.dart';

bool get _authInterceptorDebug => kDebugMode;

void _log(String msg) {
  if (_authInterceptorDebug) debugPrint('🔐 Interceptor: $msg');
}

/// Paths that must NOT get Authorization header (public auth endpoints).
bool _isPublicAuthPath(String path) {
  const public = [
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
    '/auth/logout',
    '/auth/activate',
    '/auth/resend-verification',
  ];
  return public.any((p) => path.startsWith(p) || path.contains(p));
}

class AuthInterceptor extends Interceptor {
  final Ref ref;

  AuthInterceptor(this.ref);

  bool _isRefreshing = false;
  final List<Completer<void>> _refreshWaiters = [];

  Future<void> _waitForRefresh() {
    final c = Completer<void>();
    _refreshWaiters.add(c);
    return c.future;
  }

  void _completeWaiters() {
    for (final c in _refreshWaiters) {
      if (!c.isCompleted) c.complete();
    }
    _refreshWaiters.clear();
  }

  void _failWaiters(Object error) {
    for (final c in _refreshWaiters) {
      if (!c.isCompleted) c.completeError(error);
    }
    _refreshWaiters.clear();
  }

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicAuthPath(options.path)) {
      handler.next(options);
      return;
    }
    final storage = ref.read(tokenStorageProvider);
    final access = await storage.getAccessToken();

    if (access != null && access.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $access';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final storage = ref.read(tokenStorageProvider);
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    final isAuthRefreshCall = path.contains('/auth/refresh');
    final isAuthLogoutCall = path.contains('/auth/logout');
    final isUnauthorized = status == 401;

    if (!isUnauthorized || isAuthRefreshCall || isAuthLogoutCall) {
      return handler.next(err);
    }

    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _log('401 but no refresh token');
      return handler.next(err);
    }

    if (_isRefreshing) {
      try {
        await _waitForRefresh();
        final newAccess = await storage.getAccessToken();
        if (newAccess == null) return handler.next(err);
        final retryResponse = await _retry(err.requestOptions, newAccess);
        return handler.resolve(retryResponse);
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.refresh(refreshToken);

      switch (result) {
        case AuthSuccess(data: final user):
          if (user.token.isEmpty) throw Exception('Refresh missing access token');
          await storage.saveTokens(
            accessToken: user.token,
            refreshToken: user.refreshToken.isNotEmpty
                ? user.refreshToken
                : refreshToken,
          );
          _completeWaiters();
          _isRefreshing = false;
          _log('Refresh success, retrying request');
          final retryResponse = await _retry(err.requestOptions, user.token);
          return handler.resolve(retryResponse);
        case AuthError():
          throw Exception('Refresh failed');
      }
    } catch (e) {
      _failWaiters(e);
      _isRefreshing = false;
      _log('Refresh failed: $e');
      await storage.clear();
      ref.read(sessionControllerProvider.notifier).logout();
      return handler.next(err);
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    final dio = ref.read(dioProvider);
    final opts = Options(
      method: requestOptions.method,
      headers: Map<String, dynamic>.from(requestOptions.headers)
        ..['Authorization'] = 'Bearer $accessToken',
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      followRedirects: requestOptions.followRedirects,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
      validateStatus: requestOptions.validateStatus,
    );
    return dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: opts,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}
