import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/features/auth/presentation/views/activation_processing_page.dart';
import 'package:besahub_app/features/auth/presentation/views/check_email_page.dart';
import 'package:besahub_app/features/auth/presentation/views/create_profile_page.dart';
import 'package:besahub_app/features/auth/presentation/views/login_page.dart';
import 'package:besahub_app/features/auth/presentation/views/register_page.dart';
import 'package:besahub_app/features/dashboard/customer_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/business_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/staff_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/admin_dashboard_page.dart';
import '../../features/auth/presentation/views/resend_verification_page.dart';
import '../../features/auth/presentation/views/onboarding_success_page.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/domain/entities/auth_user.dart';

// Business Onboarding imports
import '../../features/business_onboarding/pages/business_registration_entry_page.dart';
import '../../features/business_onboarding/pages/business_account_choice_page.dart';
import '../../features/business_onboarding/pages/existing_account_verify_page.dart';
import '../../features/business_onboarding/pages/new_account_for_business_page.dart';
import '../../features/business_onboarding/pages/business_details_form_page.dart';
import '../../features/business_onboarding/pages/under_review_confirmation_page.dart';
import '../../features/business_onboarding/pages/under_review_gate_page.dart';
import '../../features/business_onboarding/pages/rejected_gate_page.dart';

// Admin imports
import '../../features/admin/presentation/application_details_page.dart';

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
          '/business/register', // Allow business registration flow
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
          UserRole.businessAdmin => '/business/dashboard',
          UserRole.staff => '/staff/dashboard',
          UserRole.superAdmin => '/admin/dashboard',
        };
        debugPrint('Logged in on auth route -> Redirecting to $target');
        return target;
      }

      // If logged in, check if the active business profile is still pending (active: false)
      if (isLoggedIn &&
          (session.activeRole == UserRole.businessAdmin ||
              session.activeRole == UserRole.staff)) {
        final activeBusiness = session.user.businessProfiles.firstWhere(
          (p) => p.businessId == session.activeBusinessId,
          orElse: () => const BusinessProfileInfo(
            businessId: -1,
            businessName: '',
            role: UserRole.customer,
            active: false,
          ),
        );

        if (activeBusiness.businessId != -1 && !activeBusiness.active) {
          if (activeBusiness.status == 'REJECTED') {
            if (path != '/business/rejected') {
              debugPrint(
                'Business is rejected -> Redirecting to rejected gate',
              );
              return '/business/rejected';
            }
          } else if (path != '/business/under-review') {
            debugPrint(
              'Business is pending review -> Redirecting to under review gate',
            );
            return '/business/under-review';
          }
        }
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
        path: '/api/besahub/auth/activate',
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

      // ── Business Onboarding ──
      GoRoute(
        path: '/business/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BusinessRegistrationEntryPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/register/account-choice',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BusinessAccountChoicePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/register/existing-account',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ExistingAccountVerifyPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/register/new-account',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NewAccountForBusinessPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/register/details',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BusinessDetailsFormPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/register/under-review-confirmation',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: UnderReviewConfirmationPage(
              businessName: extra?['businessName'] as String?,
              status: extra?['status'] as String?,
            ),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/under-review',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const UnderReviewGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/rejected',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RejectedGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BusinessDashboardPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/staff/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffDashboardPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/admin/dashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/admin/business-applications/:id',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: ApplicationDetailsPage(applicationId: id),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
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
