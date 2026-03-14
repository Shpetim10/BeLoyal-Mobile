import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service to handle deep links (App Links / Universal Links).
///
/// Specifically handles email verification links:
/// https://<HOST>/api/beloyal/auth/activate?token=XYZ
class DeepLinkService {
  DeepLinkService(this.ref);
  final Ref ref;

  final _appLinks = AppLinks();
  StreamSubscription? _sub;
  String? _lastProcessedToken;
  DateTime? _lastProcessedTime;

  /// Initialize deep link listening.
  /// Should be called early in the app lifecycle (e.g. main.dart).
  Future<void> init() async {
    // 1. Handle cold start (app opened from terminated state)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkService: Failed to get initial URI: $e');
    }

    // 2. Handle runtime links (app already running/backgrounded)
    // Note: AppLinks handles stream errors internally usually, but we catch.
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleLink(uri);
      },
      onError: (err) {
        debugPrint('⚠️ DeepLinkService: Link stream error: $err');
      },
    );
  }

  void dispose() {
    _sub?.cancel();
  }

  void _handleLink(Uri uri) {
    debugPrint('🔗 DeepLink received: $uri');

    // Filter for activation links
    // Expected path: /api/besahub/auth/activate
    if (uri.path != '/api/besahub/auth/activate') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    // Debounce: prevent processing the same token multiple times in short succession
    final now = DateTime.now();
    if (_lastProcessedToken == token &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!) < const Duration(seconds: 3)) {
      debugPrint('🔗 DeepLink ignored (debounce): $token');
      return;
    }

    _lastProcessedToken = token;
    _lastProcessedTime = now;

    // Navigate to processing page
    debugPrint('🔗 DeepLink navigating to activation page with token');

    // We use the router provider to navigate.
    // Note: This assumes the router is ready.
    // try {
    //   final router = ref.read(routerProvider);
    //   router.push('/activation-processing?token=$token');
    // } catch (e) {
    //   debugPrint('⚠️ DeepLinkService: Navigation failed: $e');
    // }

    // UPDATE: GoRouter now handles the path /api/beloyal/auth/activate directly in app_router.dart.
    // We don't need to manually push here, or it might cause double navigation or conflicts.
    // We keep this service running just for logging or other links.
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});
