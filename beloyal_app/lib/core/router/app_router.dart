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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
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
          final token = state.extra as String;
          return ActivationProcessingPage(token: token);
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
