import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/features/auth/presentation/pages/activation_processing_page.dart';
import 'package:besahub_app/features/auth/presentation/pages/check_email_page.dart';
import 'package:besahub_app/features/auth/presentation/pages/create_profile_page.dart';
import 'package:besahub_app/features/auth/presentation/pages/login_page.dart';
import 'package:besahub_app/features/auth/presentation/pages/register_page.dart';
import 'package:besahub_app/features/dashboard/presentation/pages/customer_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/presentation/pages/business_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/presentation/pages/staff_dashboard_page.dart';
import 'package:besahub_app/features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/auth/presentation/pages/resend_verification_page.dart';
import '../../features/auth/presentation/pages/onboarding_success_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/staff/presentation/pages/accept_staff_invitation_page.dart';
import '../../features/staff/presentation/pages/staff_inactive_gate_page.dart';
import '../../features/staff/presentation/pages/staff_settings_pending_gate_page.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/domain/models/auth_user.dart';
import '../../features/auth/domain/models/business_status.dart';
import '../../features/auth/domain/models/business_status_helpers.dart';

// Business Onboarding imports
import '../../features/business_onboarding/presentation/pages/business_registration_entry_page.dart';
import '../../features/business_onboarding/presentation/pages/business_account_choice_page.dart';
import '../../features/business_onboarding/presentation/pages/existing_account_verify_page.dart';
import '../../features/business_onboarding/presentation/pages/new_account_for_business_page.dart';
import '../../features/business_onboarding/presentation/pages/business_details_form_page.dart';
import '../../features/business_onboarding/presentation/pages/under_review_confirmation_page.dart';
import '../../features/business_onboarding/presentation/pages/under_review_gate_page.dart';
import '../../features/business_onboarding/presentation/pages/invitation_pending_gate_page.dart';
import '../../features/business_onboarding/presentation/pages/rejected_gate_page.dart';
import '../../features/business_onboarding/presentation/pages/banned_gate_page.dart';
import '../../features/business_onboarding/presentation/pages/suspended_gate_page.dart';
import '../../features/business_onboarding/presentation/pages/update_registration_form_page.dart';

// Admin imports
import '../../features/admin/presentation/pages/application_details_page.dart';
import '../../features/admin/presentation/pages/admin_business_details_page.dart';

// Profile imports
import '../../features/profile/presentation/pages/change_password_page.dart';
import '../../features/profile/presentation/pages/admin_profile_hub_page.dart';
import '../../features/profile/presentation/pages/super_admin_profile_page.dart';
import '../../features/profile/presentation/pages/staff_profile_page.dart';

// Loyalty imports
import '../../features/business_loyalty/presentation/pages/earning_rule_management_page.dart';
import '../../features/business_loyalty/presentation/pages/business_setup_wizard_page.dart';
import '../../features/business_loyalty/presentation/pages/loyalty_settings_management_page.dart';

// Earn Points imports
import '../../features/earn_points/presentation/pages/earn_points_flow_page.dart';

// Catalog Categories imports
import '../../features/catalog_categories/presentation/pages/catalog_category_list_page.dart';

// Catalog Items imports
import '../../features/catalog_items/presentation/pages/catalog_item_list_page.dart';

// Coupons imports
import '../../features/coupons/presentation/pages/coupon_archived_page.dart';
import '../../features/coupons/presentation/pages/coupon_create_page.dart';
import '../../features/coupons/presentation/pages/coupon_detail_page.dart';
import '../../features/coupons/presentation/pages/coupon_expired_page.dart';
import '../../features/coupons/presentation/pages/coupon_list_page.dart';
import '../../features/coupons/presentation/pages/coupon_scan_page.dart';
import '../../features/coupons/presentation/pages/coupon_trash_page.dart';

// Customer onboarding imports
import '../../features/auth/presentation/pages/loyalty_card_reveal_page.dart';
import '../../features/auth/domain/models/customer_profile_creation_response.dart';

// Transaction imports
import '../../features/point_transactions/presentation/pages/customer_point_transactions_page.dart';
import '../../features/point_transactions/presentation/pages/point_transactions_page.dart';
import '../../features/point_transactions/presentation/pages/staff_point_transactions_page.dart';

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
          '/api/besahub/auth/activate',
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
          '/loyalty-card-reveal',
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

      // Route guard: Prevent non-business users (CUSTOMER, SUPERADMIN) from accessing
      // business-scoped paths. These paths are only for BUSINESSADMIN and STAFF.
      // Exception: Allow staff invitation acceptance for all users.
      if (isLoggedIn &&
          (session.activeRole == UserRole.customer ||
              session.activeRole == UserRole.superAdmin)) {
        final isInvitationAcceptance =
            path.startsWith('/api/besahub/auth/accept-invitation');

        if (!isInvitationAcceptance) {
          final businessScopedPaths = ['/business/', '/staff/'];
          final isBusinessPath =
              businessScopedPaths.any((p) => path.startsWith(p));

          if (isBusinessPath) {
            final target = switch (session.activeRole) {
              UserRole.customer =>
                session.user.customerProfileComplete
                    ? '/customer/dashboard'
                    : '/create-profile',
              UserRole.superAdmin => '/admin/dashboard',
              _ => '/login',
            };
            debugPrint(
              'Non-business user tried to access $path -> Redirecting to $target',
            );
            return target;
          }
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
        BusinessProfileInfo? activeBusiness;
        if (session.activeBusinessId != null) {
          activeBusiness = session.user.businessProfiles
              .where((p) => p.businessId == session.activeBusinessId)
              .firstOrNull;
        }
        activeBusiness ??= session.user.businessProfiles
            .where((p) => p.role == session.activeRole)
            .firstOrNull;
        activeBusiness ??= session.user.businessProfiles.firstOrNull;

        // 1. If staff member's account is deactivated, lock them to the inactive gate
        // This takes precedence over business status.
        debugPrint(
          'ROUTER CHECK: role=${session.activeRole}, bizId=${activeBusiness?.businessId}, invitationAccepted=${activeBusiness?.invitationAccepted}, memberStatus=${activeBusiness?.memberStatus}, isStaffInactive=${activeBusiness?.isStaffInactive}',
        );
        if (session.activeRole == UserRole.staff &&
            (activeBusiness?.isStaffInactive ?? false)) {
          if (path != '/staff/inactive') {
            debugPrint(
              'Staff member is INACTIVE -> Redirecting to /staff/inactive',
            );
            return '/staff/inactive';
          }
          // If already on the gate, just stay there.
          return null;
        }

        // 2 + 3. Invitation pending and under-review/rejected must be mutually exclusive
        // to avoid redirect loops.
        if (activeBusiness != null &&
            !activeBusiness.invitationAccepted &&
            path != '/business/invitation-pending') {
          debugPrint(
            'Business invitation not accepted -> Redirecting to invitation pending gate',
          );
          return '/business/invitation-pending';
        } else if (activeBusiness != null &&
            activeBusiness.invitationAccepted &&
            !activeBusiness.active) {
          final status = activeBusiness.businessStatus.toBusinessStatus();
          debugPrint(
            'BUSINESS STATUS PARSING: raw="${activeBusiness.businessStatus}" -> parsed="${status.backendValue}" (displayName="${status.displayName}")',
          );

          switch (status) {
            case BusinessStatus.rejected:
              // Allow the update form so the user can actually correct their data
              if (path != '/business/rejected' &&
                  path != '/business/rejected/update') {
                debugPrint(
                  'Business is rejected -> Redirecting to rejected gate',
                );
                return '/business/rejected';
              }
            case BusinessStatus.pendingApproval:
              if (path != '/business/under-review') {
                debugPrint(
                  'Business is pending approval -> Redirecting to under review gate',
                );
                return '/business/under-review';
              }
            case BusinessStatus.banned:
              // Banned businesses should not allow access to any business features
              if (path != '/business/banned') {
                debugPrint(
                  'Business is banned -> Redirecting to banned gate',
                );
                return '/business/banned';
              }
            case BusinessStatus.inactive:
              // Inactive (suspended) businesses should show a suspension notice
              if (path != '/business/suspended') {
                debugPrint(
                  'Business is inactive/suspended -> Redirecting to suspension gate',
                );
                return '/business/suspended';
              }
            case BusinessStatus.active:
              // Should not happen since active==false, but handle gracefully
              break;
          }
        }

        // 4. For Business Admin with an ACTIVE business, if Earning Rule or
        //    Loyalty Settings are not configured, redirect to the setup wizard.
        //    Rejected / pending businesses are already locked to their own gate
        //    pages above and must NOT be sent to the wizard.
        if (activeBusiness != null &&
            activeBusiness.active &&
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

        // 4b. For Staff on an ACTIVE business, if settings aren't configured,
        //     show a read-only pending page (they can't fix it — only the admin can).
        if (activeBusiness != null &&
            activeBusiness.active &&
            session.activeRole == UserRole.staff) {
          final needsSetup =
              !activeBusiness.earningSettingsConfigured ||
              !activeBusiness.loyaltySettingsConfigured;
          if (needsSetup && path != '/staff/settings-pending') {
            debugPrint(
              'Staff: settings not configured -> Redirecting to settings pending gate',
            );
            return '/staff/settings-pending';
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
        path: '/loyalty-card-reveal',
        pageBuilder: (context, state) {
          final response = state.extra as CustomerProfileCreationResponse?;
          // Fallback: if navigated without data (e.g. from browser back), go to dashboard
          if (response == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const SizedBox.shrink(),
              transitionsBuilder: (ctx, anim, secondAnim, child) => child,
            );
          }
          return CustomTransitionPage(
            key: state.pageKey,
            child: LoyaltyCardRevealPage(response: response),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
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
        path: '/business/invitation-pending',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const InvitationPendingGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/invitation_pending',
        redirect: (_, __) => '/business/invitation-pending',
      ),
      GoRoute(
        path: '/business/invitationPending',
        redirect: (_, __) => '/business/invitation-pending',
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
      GoRoute(
        path: '/business/rejected/update',
        pageBuilder: (context, state) {
          final businessId = state.extra as int? ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: UpdateRegistrationFormPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/suspended',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SuspendedGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/business/banned',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BannedGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
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
      GoRoute(
        path: '/staff/inactive',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffInactiveGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/staff/settings-pending',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffSettingsPendingGatePage(),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),

      // ── Business Admin & Staff Earn Points ──
      GoRoute(
        path: '/business/earn-points',
        pageBuilder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final businessId = session?.activeBusinessId ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EarnPointsFlowPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/earn-points',
        pageBuilder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final businessId = session?.activeBusinessId ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: EarnPointsFlowPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Coupon QR Scanner (Business Admin & Staff) ──
      GoRoute(
        path: '/business/scan-coupon',
        pageBuilder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final businessId = session?.activeBusinessId ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponScanPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/scan-coupon',
        pageBuilder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final businessId = session?.activeBusinessId ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponScanPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Catalog Categories ──
      GoRoute(
        path: '/business/:businessId/catalog-categories',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CatalogCategoryListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/:businessId/catalog-categories',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CatalogCategoryListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Catalog Items ──
      GoRoute(
        path: '/business/:businessId/catalog-items',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CatalogItemListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/:businessId/catalog-items',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CatalogItemListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/staff/catalog-items',
        pageBuilder: (context, state) {
          final session = ref.read(sessionControllerProvider);
          final businessId = session?.activeBusinessId ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CatalogItemListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Coupons ──
      GoRoute(
        path: '/business/:businessId/coupons',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponListPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/coupons/create',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['businessId'];
          final businessId = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponCreatePage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/coupons/archived',
        pageBuilder: (context, state) {
          final businessId =
              int.tryParse(state.pathParameters['businessId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponArchivedPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/coupons/expired',
        pageBuilder: (context, state) {
          final businessId =
              int.tryParse(state.pathParameters['businessId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponExpiredPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
      GoRoute(
        path: '/business/:businessId/coupons/trash',
        pageBuilder: (context, state) {
          final businessId =
              int.tryParse(state.pathParameters['businessId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponTrashPage(businessId: businessId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      GoRoute(
        path: '/business/:businessId/coupons/:couponId',
        pageBuilder: (context, state) {
          final businessId =
              int.tryParse(state.pathParameters['businessId'] ?? '') ?? 0;
          final couponId =
              int.tryParse(state.pathParameters['couponId'] ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: CouponDetailPage(businessId: businessId, couponId: couponId),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),

      // ── Point Transactions ──
      GoRoute(
        path: '/business/:businessId/transactions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PointTransactionsPage(showAppBar: true),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
      GoRoute(
        path: '/staff/:businessId/transactions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StaffPointTransactionsPage(showAppBar: true),
          transitionsBuilder: (ctx, anim, secondAnim, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      ),
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
        path: '/customer/transactions',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CustomerPointTransactionsPage(),
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
      GoRoute(
        path: '/admin/businesses/:id',
        pageBuilder: (context, state) {
          final idParam = state.pathParameters['id'];
          final id = int.tryParse(idParam ?? '') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: AdminBusinessDetailsPage(businessId: id),
            transitionsBuilder: (ctx, anim, secondAnim, child) =>
                FadeTransition(opacity: anim, child: child),
          );
        },
      ),
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
      GoRoute(
        path: '/profile',
        redirect: (context, state) => '/customer/dashboard',
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
