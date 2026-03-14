import './auth_user.dart';

/// Represents the currently active session throughout the app.
class Session {
  const Session({
    required this.user,
    required this.activeRole,
    this.activeBusinessId,
    this.activeBusinessName,
  });

  final AuthUser user;
  final UserRole activeRole;
  final int? activeBusinessId;
  final String? activeBusinessName;

  String get token => user.token;

  Session copyWith({
    AuthUser? user,
    UserRole? activeRole,
    int? activeBusinessId,
    String? activeBusinessName,
    bool clearBusinessId = false,
  }) {
    return Session(
      user: user ?? this.user,
      activeRole: activeRole ?? this.activeRole,
      activeBusinessId: clearBusinessId
          ? null
          : (activeBusinessId ?? this.activeBusinessId),
      activeBusinessName: clearBusinessId
          ? null
          : (activeBusinessName ?? this.activeBusinessName),
    );
  }
}
