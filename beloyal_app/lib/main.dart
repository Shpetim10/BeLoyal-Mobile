import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './core/router/app_router.dart';
import './core/services/deep_link_service.dart';
import './core/theme/app_theme.dart';
import './features/auth/presentation/controllers/auth_controller.dart';
import './features/splash/presentation/pages/video_splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: BesaHubApp()));
}

class BesaHubApp extends ConsumerStatefulWidget {
  const BesaHubApp({super.key});

  @override
  ConsumerState<BesaHubApp> createState() => _BesaHubAppState();
}

class _BesaHubAppState extends ConsumerState<BesaHubApp> {
  bool _isVideoFinished = false;

  @override
  void initState() {
    super.initState();
    ref.read(deepLinkServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    final startupAsync = ref.watch(authStartupProvider);

    final isAppReady =
        startupAsync.hasValue && !startupAsync.hasError && !startupAsync.isLoading;
    final hasError = startupAsync.hasError;

    if (hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
                child: Text('Fatal Error: ${startupAsync.error}',
                    style: const TextStyle(color: Colors.white)))),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: (!isAppReady || !_isVideoFinished)
          ? MaterialApp(
              key: const ValueKey('splash'),
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: VideoSplashScreen(
                isAppReady: isAppReady,
                onVideoFinished: () {
                  if (mounted) {
                    setState(() {
                      _isVideoFinished = true;
                    });
                  }
                },
              ),
            )
          : Builder(
              key: const ValueKey('app'),
              builder: (context) {
                final router = ref.watch(routerProvider);
                return MaterialApp.router(
                  title: 'BesaHub',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light,
                  darkTheme: AppTheme.dark,
                  themeMode: ThemeMode.dark,
                  routerConfig: router,
                );
              },
            ),
    );
  }
}

