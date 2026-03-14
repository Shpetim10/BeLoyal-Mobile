import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './core/router/app_router.dart';
import './core/services/deep_link_service.dart';
import './core/theme/app_theme.dart';
import './features/auth/presentation/controllers/auth_controller.dart';

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
    ref.read(deepLinkServiceProvider).init();
  }

  @override
  Widget build(BuildContext context) {
    final startupAsync = ref.watch(authStartupProvider);

    return startupAsync.when(
      data: (_) {
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
      loading: () => const _SplashScreen(),
      error: (e, st) => MaterialApp(
        home: Scaffold(body: Center(child: Text('Fatal Error: $e'))),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Slate 900
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF38BDF8), Color(0xFF818CF8)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
