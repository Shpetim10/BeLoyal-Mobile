import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/session.dart';

/// Global session state. Holds the authenticated user + active role.
/// Null == unauthenticated.
class SessionController extends Notifier<Session?> {
  @override
  Session? build() => null;

  /// Called after successful login + role selection.
  void establish(AuthUser user, UserRole role) {
    state = Session(user: user, activeRole: role);
  }

  /// Helper to set session from AuthUser, picking the first role as default.
  Future<void> setSession(AuthUser user) async {
    if (user.roles.isEmpty) {
      // Fallback or error? Assuming at least one role exists.
      // For now, if no roles, we can't really set a valid session with activeRole.
      // But let's assume CUSTOMER if empty or handle it.
      // However, AuthUser usually validates roles.
      return;
    }
    state = Session(user: user, activeRole: user.roles.first);
  }

  /// Switch role without re-login.
  void switchRole(UserRole role) {
    final current = state;
    if (current != null) {
      state = current.copyWith(activeRole: role);
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
