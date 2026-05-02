import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../router/app_router.dart';

/// Service to handle deep links via the besahub:// custom scheme.
///
/// URIs must use triple-slash form so the full path is unambiguous:
///   besahub:///api/besahub/auth/activate?token=XYZ
/// Dart parses these with an empty host and the full path in uri.path.
class DeepLinkService {
  DeepLinkService(this.ref);
  final Ref ref;

  final _appLinks = AppLinks();
  StreamSubscription? _sub;
  String? _lastProcessedToken;
  DateTime? _lastProcessedTime;

  Future<void> init() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e) {
      debugPrint('⚠️ DeepLinkService: Failed to get initial URI: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(
      _handleLink,
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

    // URIs use triple-slash form (besahub:///api/besahub/auth/activate),
    // so uri.host is empty and uri.path is the full logical path.
    final String fullPath = uri.path;

    final query = uri.queryParameters;

    if (fullPath == '/api/besahub/auth/activate') {
      _handleActivate(fullPath, query);
    } else if (fullPath == '/api/besahub/auth/accept-invitation') {
      _handleAcceptInvitation(fullPath, query);
    } else if (fullPath == '/forget-password') {
      _handleResetPassword(fullPath, query);
    } else {
      debugPrint('🔗 DeepLink: unhandled path $fullPath');
    }
  }

  void _handleActivate(String path, Map<String, String> query) {
    final token = query['token'];
    if (token == null || token.isEmpty) return;

    // Debounce identical token within 3 s to avoid double-processing.
    final now = DateTime.now();
    if (_lastProcessedToken == token &&
        _lastProcessedTime != null &&
        now.difference(_lastProcessedTime!) < const Duration(seconds: 3)) {
      debugPrint('🔗 DeepLink ignored (debounce): $token');
      return;
    }
    _lastProcessedToken = token;
    _lastProcessedTime = now;

    debugPrint('🔗 DeepLink: navigating to activation');
    _navigate(path, query);
  }

  void _handleAcceptInvitation(String path, Map<String, String> query) {
    final token = query['token'];
    if (token == null || token.isEmpty) return;

    debugPrint('🔗 DeepLink: navigating to accept-invitation');
    _navigate(path, query);
  }

  void _handleResetPassword(String path, Map<String, String> query) {
    final token = query['token'];
    if (token == null || token.isEmpty) return;

    debugPrint('🔗 DeepLink: navigating to reset-password');
    _navigate(path, query);
  }

  void _navigate(String path, Map<String, String> query) {
    try {
      final router = ref.read(routerProvider);
      final queryString = query.entries
          .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
          .join('&');
      final location = queryString.isEmpty ? path : '$path?$queryString';
      router.go(location);
    } catch (e) {
      debugPrint('⚠️ DeepLinkService: Navigation failed: $e');
    }
  }
}

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  return DeepLinkService(ref);
});
