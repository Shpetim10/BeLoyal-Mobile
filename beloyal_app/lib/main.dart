import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/services/deep_link_service.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: BesaHubApp()));
}

class BesaHubApp extends ConsumerStatefulWidget {
  const BesaHubApp({super.key});

  @override
  ConsumerState<BesaHubApp> createState() => _BesaHubAppState();
}

class _BesaHubAppState extends ConsumerState<BesaHubApp> {
  @override
  void initState() {
    super.initState();
    // Initialize Deep Link Service to listen for incoming links
    ref.read(deepLinkServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'BesaHub',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
