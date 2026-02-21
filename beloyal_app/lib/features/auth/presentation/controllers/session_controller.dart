import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/session.dart';

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
  /// Defaults to CUSTOMER if present, otherwise picks the first available business.
  Future<void> setSession(AuthUser user) async {
    if (user.roles.isEmpty && user.businessProfiles.isEmpty) {
      return;
    }

    // Default 1: Customer (if they have the role)
    if (user.roles.contains(UserRole.customer)) {
      state = Session(user: user, activeRole: UserRole.customer);
      return;
    }

    // Default 2: First active business profile
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

    // Default 3: Platform Admin or whatever is first
    state = Session(
      user: user,
      activeRole: user.roles.firstOrNull ?? UserRole.customer,
    );
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

  /// Logout — clears session.
  void logout() {
    state = null;
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, Session?>(
  SessionController.new,
);
