import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/features/auth/presentation/views/activation_processing_page.dart';
import 'package:besahub_app/features/auth/presentation/views/check_email_page.dart';
import 'package:besahub_app/features/auth/presentation/views/create_profile_page.dart';
import 'package:besahub_app/features/auth/presentation/views/login_page.dart';
import 'package:besahub_app/features/auth/presentation/views/register_page.dart';
import 'package:besahub_app/features/dashboard/customer_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/placeholder_dashboard_page.dart';

import '../../features/auth/presentation/views/resend_verification_page.dart';
import '../../features/auth/presentation/views/onboarding_success_page.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/domain/entities/auth_user.dart';

final routerListenableProvider = Provider((ref) => RouterListenable(ref));

class RouterListenable extends ChangeNotifier {
  RouterListenable(Ref ref) {
    ref.listen(sessionControllerProvider, (prev, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    debugLogDiagnostics: true, // Enable GoRouter's own logging
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final isLoggedIn = session != null;
      final path = state.uri.path;

      debugPrint('--- Router Redirect Check ---');
      debugPrint('Path: $path');
      debugPrint('IsLoggedIn: $isLoggedIn');
      if (isLoggedIn) {
        debugPrint('Active Role: ${session.activeRole}');
      }

      final isAuthRoute = path == '/login' || path == '/register';

      if (!isLoggedIn) {
        final allowedPaths = [
          '/login',
          '/register',
          '/check-email',
          '/activation-processing',
          '/api/beloyal/auth/activate',
          '/resend-verification',
          '/forgot-password',
        ];
        final isAllowed = allowedPaths.any((p) => path.startsWith(p));

        if (!isAllowed) {
          debugPrint('Unauthorized access to $path -> Redirecting to /login');
          return '/login';
        }
        return null;
      }

      // If logged in and on an auth route, go to respective dashboard
      if (isAuthRoute) {
        final target = switch (session.activeRole) {
          UserRole.customer => '/customer/dashboard',
          UserRole.restaurantAdmin => '/business/dashboard',
          UserRole.staff => '/staff/dashboard',
          UserRole.platformAdmin => '/admin/dashboard',
        };
        debugPrint('Logged in on auth route -> Redirecting to $target');
        return target;
      }

      debugPrint('Proceeding to $path');
      return null;
    },
    routes: [
      // ── Auth ──
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/check-email',
        pageBuilder: (context, state) {
          final email = state.extra as String?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CheckEmailPage(email: email),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/activation-processing',
        builder: (context, state) {
          final token =
              state.extra as String? ?? state.uri.queryParameters['token'];
          if (token == null) return const LoginPage();
          return ActivationProcessingPage(token: token);
        },
      ),

      // Deep link route (from email)
      GoRoute(
        path: '/api/beloyal/auth/activate',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          if (token == null) return const LoginPage();
          return ActivationProcessingPage(token: token);
        },
      ),

      // NEW: Resend verification route
      GoRoute(
        path: '/resend-verification',
        builder: (context, state) {
          final email = state.extra as String?;
          return ResendVerificationPage(email: email);
        },
      ),
      GoRoute(
        path: '/create-profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateProfilePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/onboarding-success',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OnboardingSuccessPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const _PlaceholderPage(
          title: 'Forgot Password',
          icon: Icons.lock_reset_rounded,
          message: 'Password reset flow will be implemented here.',
        ),
      ),

      // ── Dashboards ──
      GoRoute(
        path: '/customer/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomerDashboardPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/dashboard',
        builder: (context, state) => const PlaceholderDashboardPage(
          title: 'Business Dashboard',
          icon: Icons.storefront_outlined,
        ),
      ),
      GoRoute(
        path: '/staff/dashboard',
        builder: (context, state) => const PlaceholderDashboardPage(
          title: 'Staff Dashboard',
          icon: Icons.badge_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const PlaceholderDashboardPage(
          title: 'Admin Dashboard',
          icon: Icons.admin_panel_settings_outlined,
        ),
      ),
    ],
  );
});

/// Minimal placeholder page for unimplemented routes.
class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({
    required this.title,
    required this.icon,
    required this.message,
  });
  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}
