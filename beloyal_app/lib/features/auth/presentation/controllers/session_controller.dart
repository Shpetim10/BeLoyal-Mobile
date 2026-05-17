import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/models/session.dart';

/// Global session state. Holds the authenticated user + active role.
/// Null == unauthenticated.
class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Called after successful login + role selection.
  void establish(
    AuthUser user,
    UserRole role, {
    int? businessId,
    String? businessName,
  }) {
    state = Session(
      user: user,
      activeRole: role,
      activeBusinessId: businessId,
      activeBusinessName: businessName,
    );
  }

  /// Helper to set session from AuthUser, picking the first role as default.
  /// Prioritizes independent global roles (CUSTOMER, SUPERADMIN) over business-scoped roles.
  Future<void> setSession(AuthUser user) async {
    if (user.roles.isEmpty && user.businessProfiles.isEmpty) {
      return;
    }

    // Default 1: SuperAdmin (if they have the role) - independent global role
    if (user.roles.contains(UserRole.superAdmin)) {
      state = Session(user: user, activeRole: UserRole.superAdmin);
      return;
    }

    // Default 2: Customer (if they have the role) - independent global role
    if (user.roles.contains(UserRole.customer)) {
      state = Session(user: user, activeRole: UserRole.customer);
      return;
    }

    // Default 3: First active business profile (BUSINESSADMIN, STAFF)
    if (user.hasActiveBusinessProfiles) {
      final firstProfile = user.businessProfiles
          .where((p) => p.active)
          .firstOrNull;
      if (firstProfile != null) {
        state = Session(
          user: user,
          activeRole: firstProfile.role,
          activeBusinessId: firstProfile.businessId,
          activeBusinessName: firstProfile.businessName,
        );
        return;
      }
    }

    // Default 4: Any business profile (even if inactive)
    if (user.businessProfiles.isNotEmpty) {
      final firstProfile = user.businessProfiles.first;
      state = Session(
        user: user,
        activeRole: firstProfile.role,
        activeBusinessId: firstProfile.businessId,
        activeBusinessName: firstProfile.businessName,
      );
      return;
    }

    // Default 5: Fallback to any global role
    if (user.roles.isNotEmpty) {
      state = Session(user: user, activeRole: user.roles.first);
      return;
    }

    // Failure fallback: should not happen if login succeeded
    state = null;
  }

  /// Silently update the user state (e.g. after a token refresh)
  /// without losing the active role/business selection.
  void updateUser(AuthUser newUser) {
    final current = state;
    if (current != null) {
      state = current.copyWith(user: newUser);
    }
  }

  /// Switch role without re-login.
  void switchRole(UserRole role, {int? businessId, String? businessName}) {
    final current = state;
    if (current != null) {
      state = current.copyWith(
        activeRole: role,
        activeBusinessId: businessId,
        activeBusinessName: businessName,
        clearBusinessId: businessId == null,
      );
    }
  }

  /// Mark profile as complete and ensure CUSTOMER role is present locally.
  void completeProfile() {
    final current = state;
    if (current != null) {
      final newUser = current.user.copyWith(
        customerProfileComplete: true,
        roles: {...current.user.roles, UserRole.customer},
      );
      state = current.copyWith(user: newUser, activeRole: UserRole.customer);
    }
  }

  /// Remove customer role after account deletion, preserving current business role.
  void removeCustomerRole() {
    final current = state;
    if (current != null) {
      final newRoles = Set<UserRole>.from(current.user.roles)
        ..remove(UserRole.customer);
      final newUser = current.user.copyWith(
        roles: newRoles,
        customerProfileComplete: false,
      );
      state = current.copyWith(user: newUser);
    }
  }

  /// Logout — clears session.
  void logout() {
    state = null;
  }

  /// Updates local tracking of earning settings flags for a specific business profile.
  void updateEarningSettingsFlags({
    required int businessId,
    required bool configured,
    required bool enabled,
  }) {
    final current = state;
    if (current == null) return;

    final updatedProfiles = current.user.businessProfiles.map((p) {
      if (p.businessId == businessId) {
        return BusinessProfileInfo(
          businessId: p.businessId,
          businessName: p.businessName,
          role: p.role,
          active: p.active,
          invitationAccepted: p.invitationAccepted,
          businessStatus: p.businessStatus,
          statusDisplayName: p.statusDisplayName,
          statusDescription: p.statusDescription,
          rejectionReason: p.rejectionReason,
          memberStatus: p.memberStatus,
          earningSettingsEnabled: enabled,
          earningSettingsConfigured: configured,
          loyaltySettingsEnabled: p.loyaltySettingsEnabled,
          loyaltySettingsConfigured: p.loyaltySettingsConfigured,
          currency: p.currency,
        );
      }
      return p;
    }).toList();

    final newUser = current.user.copyWith(businessProfiles: updatedProfiles);
    state = current.copyWith(user: newUser);
  }

  /// Updates local tracking of business status (e.g. from REJECTED to PENDING)
  /// and clears rejection reason.
  void updateBusinessStatus({
    required int businessId,
    required String newStatus,
    String? statusDisplayName,
    String? statusDescription,
    String? rejectionReason,
  }) {
    final current = state;
    if (current == null) return;

    final updatedProfiles = current.user.businessProfiles.map((p) {
      if (p.businessId == businessId) {
        return BusinessProfileInfo(
          businessId: p.businessId,
          businessName: p.businessName,
          role: p.role,
          active: p.active,
          invitationAccepted: p.invitationAccepted,
          businessStatus: newStatus,
          statusDisplayName: statusDisplayName,
          statusDescription: statusDescription,
          rejectionReason: rejectionReason,
          memberStatus: p.memberStatus,
          earningSettingsEnabled: p.earningSettingsEnabled,
          earningSettingsConfigured: p.earningSettingsConfigured,
          loyaltySettingsEnabled: p.loyaltySettingsEnabled,
          loyaltySettingsConfigured: p.loyaltySettingsConfigured,
          currency: p.currency,
        );
      }
      return p;
    }).toList();

    final newUser = current.user.copyWith(businessProfiles: updatedProfiles);
    state = current.copyWith(user: newUser);
  }

  /// Updates local tracking of loyalty (redemption) settings flags for a specific business profile.
  void updateLoyaltySettingsFlags({
    required int businessId,
    required bool configured,
    required bool enabled,
  }) {
    final current = state;
    if (current == null) return;

    final updatedProfiles = current.user.businessProfiles.map((p) {
      if (p.businessId == businessId) {
        return BusinessProfileInfo(
          businessId: p.businessId,
          businessName: p.businessName,
          role: p.role,
          active: p.active,
          invitationAccepted: p.invitationAccepted,
          businessStatus: p.businessStatus,
          statusDisplayName: p.statusDisplayName,
          statusDescription: p.statusDescription,
          rejectionReason: p.rejectionReason,
          memberStatus: p.memberStatus,
          earningSettingsEnabled: p.earningSettingsEnabled,
          earningSettingsConfigured: p.earningSettingsConfigured,
          loyaltySettingsEnabled: enabled,
          loyaltySettingsConfigured: configured,
          currency: p.currency,
        );
      }
      return p;
    }).toList();

    final newUser = current.user.copyWith(businessProfiles: updatedProfiles);
    state = current.copyWith(user: newUser);
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);

/// Derives the active business currency code from the session.
/// Returns the ISO code (e.g. 'ALL', 'EUR', 'USD') or null when not in a
/// business context. Callers should fall back to 'ALL' when null.
final activeBusinessCurrencyProvider = Provider<String?>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final businessId = session?.activeBusinessId;
  if (businessId == null) return null;
  return session!.user.businessProfiles
      .where((p) => p.businessId == businessId)
      .map((p) => p.currency)
      .firstOrNull;
});
