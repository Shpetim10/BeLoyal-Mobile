import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/token_storage.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/controllers/session_controller.dart';

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
  return public.any((p) => path.endsWith(p) || path.contains(p));
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

    bool isRefreshCall(String p) =>
        p.endsWith('/auth/refresh') || p.endsWith('/refresh');
    bool isLogoutCall(String p) =>
        p.endsWith('/auth/logout') || p.endsWith('/logout');

    _log('Error at $path: status=$status type=${err.type}');

    // Don't intercept refresh/logout failures here
    if (isRefreshCall(path) || isLogoutCall(path)) {
      return handler.next(err);
    }

    // Request refresh on 401 (Unauthorized) or 403 (Forbidden, specifically for JWT versioning mismatch)
    final shouldRefresh = status == 401 || status == 403;
    if (!shouldRefresh) {
      return handler.next(err);
    }

    final refreshToken = await storage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      _log('401 but no refresh token -> pass through');
      return handler.next(err);
    }

    // If already refreshing, wait and retry
    if (_isRefreshing) {
      _log('Already refreshing, waiting...');
      try {
        await _waitForRefresh();
        final newAccess = await storage.getAccessToken();
        if (newAccess == null || newAccess.isEmpty) return handler.next(err);
        final retryResponse = await _retry(err.requestOptions, newAccess);
        return handler.resolve(retryResponse);
      } catch (e) {
        _log('Wait refresh failed: $e');
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    try {
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: err.requestOptions.baseUrl,
          connectTimeout: err.requestOptions.connectTimeout,
          receiveTimeout: err.requestOptions.receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (_authInterceptorDebug) {
        refreshDio.interceptors.add(
          LogInterceptor(
            requestBody: true,
            responseBody: true,
            logPrint: (obj) => debugPrint('🔄 Refresh: $obj'),
          ),
        );
      }

      final repo = AuthRepositoryImpl(refreshDio);
      final result = await repo.refresh(refreshToken);

      switch (result) {
        case AuthSuccess(data: final user):
          if (user.token.isEmpty)
            throw Exception('Refresh missing access token');

          await storage.saveTokens(
            accessToken: user.token,
            refreshToken: user.refreshToken.isNotEmpty
                ? user.refreshToken
                : refreshToken,
          );

          ref.read(sessionControllerProvider.notifier).updateUser(user);

          _completeWaiters();
          _isRefreshing = false;

          final retryResponse = await _retry(err.requestOptions, user.token);
          return handler.resolve(retryResponse);

        case AuthError(failure: final f):
          throw DioException(
            requestOptions: err.requestOptions,
            response: err.response,
            error: f.message,
            type: DioExceptionType.badResponse,
          );
      }
    } catch (e) {
      _failWaiters(e);
      _isRefreshing = false;

      if (e is DioException) {
        final sc = e.response?.statusCode;
        if (sc == 401 || sc == 403) {
          _log('Refresh token invalid -> logout');
          await storage.clear();
          ref.read(sessionControllerProvider.notifier).logout();
        } else {
          _log('Refresh failed: [${e.runtimeType}] $e');
        }
        return handler.next(e);
      } else {
        _log('Refresh failed: [${e.runtimeType}] $e');
        return handler.next(err);
      }
    }
  }

  Future<Response<dynamic>> _retry(
    RequestOptions requestOptions,
    String accessToken,
  ) async {
    final dio = Dio(
      BaseOptions(
        baseUrl: requestOptions.baseUrl,
        connectTimeout: requestOptions.connectTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
    );

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
      data: await _cloneData(requestOptions),
      queryParameters: requestOptions.queryParameters,
      options: opts,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }

  Future<dynamic> _cloneData(RequestOptions requestOptions) async {
    final data = requestOptions.data;
    final extra = requestOptions.extra;

    if (extra['isFormData'] == true) {
      final clone = FormData();
      final fields = extra['formDataFields'] as List<MapEntry<String, String>>?;
      if (fields != null) clone.fields.addAll(fields);

      final files = extra['formDataFiles'] as List<dynamic>?;
      if (files != null) {
        for (final fileInfo in files) {
          if (fileInfo is Map) {
            clone.files.add(
              MapEntry(
                fileInfo['key']?.toString() ?? 'file',
                await MultipartFile.fromFile(
                  fileInfo['path'].toString(),
                  filename: fileInfo['filename']?.toString(),
                ),
              ),
            );
          }
        }
      }
      return clone;
    }

    return data;
  }
}
