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
import '../../features/auth/presentation/views/forgot_password_page.dart';
import '../../features/auth/presentation/views/reset_password_page.dart';
import '../../features/staff/presentation/views/accept_staff_invitation_page.dart';
import '../../features/staff/presentation/views/staff_inactive_gate_page.dart';

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

// Profile imports
import '../../features/profile/presentation/views/profile_page.dart';
import '../../features/profile/presentation/views/change_password_page.dart';
import '../../features/profile/presentation/views/admin_profile_hub_page.dart';
import '../../features/profile/presentation/views/super_admin_profile_page.dart';
import '../../features/profile/presentation/views/staff_profile_page.dart';

// Loyalty imports
import '../../features/business_loyalty/presentation/pages/earning_rule_management_page.dart';
import '../../features/business_loyalty/presentation/pages/business_setup_wizard_page.dart';
import '../../features/business_loyalty/presentation/pages/loyalty_settings_management_page.dart';

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
          '/api/besahub/auth/accept-invitation', // Staff invite deep link
          '/resend-verification',
          '/forgot-password',
          '/forget-password', // Deep link from email
          '/api/besahub/auth/reset-password',
          '/business/register', // Allow business registration flow
        ];
        final isAllowed = allowedPaths.any((p) => path.startsWith(p));

        if (!isAllowed) {
          debugPrint('Unauthorized access to $path -> Redirecting to /login');
          return '/login';
        }
        return null;
      }

      // If Customer and profile not complete, force redirect to /create-profile
      if (isLoggedIn &&
          session.activeRole == UserRole.customer &&
          !session.user.customerProfileComplete) {
        final allowedDuringOnboarding = [
          '/create-profile',
          '/onboarding-success',
          '/login',
          '/register',
          '/check-email',
          '/resend-verification',
        ];

        if (!allowedDuringOnboarding.any((p) => path.startsWith(p))) {
          debugPrint(
            'Customer profile incomplete -> Redirecting to /create-profile',
          );
          return '/create-profile';
        }
      }

      // If logged in, check if the active business profile is still pending (active: false)
      // Skip this check for the staff invitation acceptance route — invited staff must
      // always be able to accept even if their business isn't active yet.
      final isInvitationRoute = path.startsWith(
        '/api/besahub/auth/accept-invitation',
      );
      if (!isInvitationRoute &&
          isLoggedIn &&
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

        // 1. If staff member's account is deactivated, lock them to the inactive gate
        // This takes precedence over business status.
        debugPrint(
          'ROUTER CHECK: role=${session.activeRole}, bizId=${activeBusiness.businessId}, memberStatus=${activeBusiness.memberStatus}, isStaffInactive=${activeBusiness.isStaffInactive}',
        );
        if (session.activeRole == UserRole.staff &&
            activeBusiness.isStaffInactive) {
          if (path != '/staff/inactive') {
            debugPrint(
              'Staff member is INACTIVE -> Redirecting to /staff/inactive',
            );
            return '/staff/inactive';
          }
          // If already on the gate, just stay there.
          return null;
        }

        // 2. Otherwise, if business is inactive (pending/rejected), lock to those gates
        if (activeBusiness.businessId != -1 && !activeBusiness.active) {
          if (activeBusiness.businessStatus == 'REJECTED') {
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

        // 3. For Business Admin, if Earning Rule or Loyalty Settings not configured, redirect to unified wizard
        if (activeBusiness.businessId != -1 &&
            session.activeRole == UserRole.businessAdmin) {
          final needsSetup =
              !activeBusiness.earningSettingsConfigured ||
              !activeBusiness.loyaltySettingsConfigured;
          if (needsSetup) {
            final wizardPath =
                '/business/${activeBusiness.businessId}/onboarding/loyalty-setup';
            if (path != wizardPath) {
              debugPrint(
                'Settings not fully configured -> Redirecting to unified wizard',
              );
              return wizardPath;
            }
          }
        }
      }

      // If logged in and on an auth route (e.g., /login or /register), and they
      // have passed all gate checks above, redirect them to their dashboard.
      if (isAuthRoute && isLoggedIn) {
        final target = switch (session.activeRole) {
          UserRole.customer =>
            session.user.customerProfileComplete
                ? '/customer/dashboard'
                : '/create-profile',
          UserRole.businessAdmin => '/business/dashboard',
          UserRole.staff => '/staff/dashboard',
          UserRole.superAdmin => '/admin/dashboard',
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
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/api/besahub/auth/reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ResetPasswordPage(token: token),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/forget-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return CustomTransitionPage(
            key: state.pageKey,
            child: ResetPasswordPage(token: token),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
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

      // ── Staff Invitation ──
      GoRoute(
        path: '/api/besahub/auth/accept-invitation',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final existing = state.uri.queryParameters['existing'] == 'true';
          final email = state.uri.queryParameters['email'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: AcceptStaffInvitationPage(
              token: token,
              isExistingUser: existing,
              email: email,
            ),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Staff Inactive Gate ──
      GoRoute(
        path: '/staff/inactive',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffInactiveGatePage(),
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

      // ── Business Loyalty ──
      GoRoute(
        path: '/business/:businessId/onboarding/loyalty-setup',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BusinessSetupWizardPage(businessId: id),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/loyalty/earning-rule',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EarningRuleManagementPage(businessId: id),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/loyalty/settings',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: LoyaltySettingsManagementPage(businessId: id),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Profile ──
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfilePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/admin/profile',
        pageBuilder: (context, state) {
          final tab = state.uri.queryParameters['tab'] == '1' ? 1 : 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AdminProfileHubPage(initialTab: tab),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/profile',
        redirect: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final role = session?.activeRole;
          if (role != UserRole.staff && role != UserRole.superAdmin) {
            return '/customer/dashboard';
          }
          return null;
        },
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffProfilePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/superadmin/profile',
        redirect: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final role = session?.activeRole;
          if (role != UserRole.superAdmin) {
            return '/customer/dashboard';
          }
          return null;
        },
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SuperAdminProfilePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/profile/change-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChangePasswordPage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
    ],
  );
});
