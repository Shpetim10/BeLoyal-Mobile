import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './auth_interceptor.dart';

/// Central Dio instance configured for the BesaHub Spring Boot API.
///
/// ⚠ For **physical Android device** on same WiFi as PC:
///   Replace `localhost` with your PC's local IP, e.g. `192.168.1.x`.
/// ⚠ For **Android emulator**:
///   Use `10.0.2.2` instead of `localhost`.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://ended-julie-arts-covers.trycloudflare.com/api/besahub',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('🌐 $obj'),
    ),
  );

  return dio;
});
