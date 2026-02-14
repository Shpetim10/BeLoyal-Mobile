/// Roles matching Spring Boot `Role` enum.
enum UserRole {
  customer,
  restaurantAdmin,
  staff,
  platformAdmin;

  /// Mapping from backend string (e.g. "ROLE_CUSTOMER") to enum.
  static UserRole fromBackend(String raw) {
    final normalized = raw.replaceFirst('ROLE_', '').toLowerCase();
    return switch (normalized) {
      'customer' => UserRole.customer,
      'restaurant_admin' || 'restaurantadmin' => UserRole.restaurantAdmin,
      'staff' => UserRole.staff,
      'platform_admin' || 'platformadmin' => UserRole.platformAdmin,
      _ => UserRole.customer,
    };
  }

  String get displayName => switch (this) {
    UserRole.customer => 'Customer',
    UserRole.restaurantAdmin => 'Restaurant Admin',
    UserRole.staff => 'Staff',
    UserRole.platformAdmin => 'Platform Admin',
  };

  String get icon => switch (this) {
    UserRole.customer => '🛒',
    UserRole.restaurantAdmin => '🏪',
    UserRole.staff => '👤',
    UserRole.platformAdmin => '🛡️',
  };
}

/// Authenticated user returned after login.
class AuthUser {
  const AuthUser({
    required this.token,
    required this.tokenType,
    required this.roles,
    required this.emailVerified,
    required this.customerProfileComplete,
    this.alreadyVerified = false,
    required this.hasMultipleRoles
  });

  final String token;
  final String tokenType;
  final Set<UserRole> roles;
  final bool emailVerified;
  final bool customerProfileComplete;
  final bool alreadyVerified;
  final bool hasMultipleRoles;
}
