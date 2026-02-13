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
