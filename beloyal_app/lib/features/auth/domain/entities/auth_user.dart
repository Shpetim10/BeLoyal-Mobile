/// Roles matching Spring Boot `Role` enum.
enum UserRole {
  customer,
  businessAdmin,
  staff,
  superAdmin;

  /// Mapping from backend string (e.g. "ROLE_CUSTOMER") to enum.
  static UserRole fromBackend(String raw) {
    final normalized = raw.replaceFirst('ROLE_', '').toUpperCase();
    return switch (normalized) {
      'CUSTOMER' => UserRole.customer,
      'BUSINESS_ADMIN' => UserRole.businessAdmin,
      'STAFF' => UserRole.staff,
      'PLATFORM_ADMIN' || 'SUPER_ADMIN' || 'ADMIN' => UserRole.superAdmin,
      _ => UserRole.customer,
    };
  }

  String get displayName => switch (this) {
    UserRole.customer => 'Customer',
    UserRole.businessAdmin => 'Business Admin',
    UserRole.staff => 'Staff',
    UserRole.superAdmin => 'Super Admin',
  };

  String get icon => switch (this) {
    UserRole.customer => '🛒',
    UserRole.businessAdmin => '🏪',
    UserRole.staff => '👤',
    UserRole.superAdmin => '🛡️',
  };
}

/// Business profile information from backend.
class BusinessProfileInfo {
  const BusinessProfileInfo({
    required this.businessId,
    required this.businessName,
    required this.role,
    required this.active,
    this.status,
    this.rejectionReason,
  });

  final int businessId;
  final String businessName;
  final UserRole role;
  final bool active;
  final String? status;
  final String? rejectionReason;
}

/// Authenticated user returned after login.
class AuthUser {
  const AuthUser({
    required this.token,
    required this.tokenType,
    required this.refreshToken,
    required this.roles,
    this.emailVerified = false,
    this.customerProfileComplete = false,
    this.alreadyVerified = false,
    required this.hasMultipleRoles,
    required this.businessProfiles,
  });

  final String token;
  final String tokenType;
  final String refreshToken;
  final Set<UserRole> roles;
  final bool emailVerified;
  final bool customerProfileComplete;
  final bool alreadyVerified;
  final bool hasMultipleRoles;

  /// List of business profiles and roles.
  final List<BusinessProfileInfo> businessProfiles;

  /// Returns true if the user can switch between different roles or businesses.
  bool get canSwitchRoles {
    // A user can switch if they have more than one "entry point"
    return (roles.length + businessProfiles.length) > 1;
  }

  /// Returns true if the user has at least one active business profile.
  bool get hasActiveBusinessProfiles =>
      businessProfiles.any((profile) => profile.active);

  /// Returns IDs of active business profiles.
  List<int> get activeBusinessIds =>
      businessProfiles.where((p) => p.active).map((p) => p.businessId).toList();
}
