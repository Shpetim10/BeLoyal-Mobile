import 'auth_user.dart';

/// Represents the currently active session throughout the app.
class Session {
  const Session({required this.user, required this.activeRole});

  final AuthUser user;
  final UserRole activeRole;

  String get token => user.token;

  Session copyWith({UserRole? activeRole}) =>
      Session(user: user, activeRole: activeRole ?? this.activeRole);
}
