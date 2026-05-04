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
      _ => UserRole.customer, // Fallback for truly unknown roles
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
    this.invitationAccepted = true,
    this.businessStatus,
    this.rejectionReason,
    this.memberStatus,
    this.earningSettingsEnabled = false,
    this.earningSettingsConfigured = false,
    this.loyaltySettingsEnabled = false,
    this.loyaltySettingsConfigured = false,
  });

  final int businessId;
  final String businessName;
  final UserRole role;
  final bool active;
  final bool invitationAccepted;
  final String? businessStatus;
  final String? rejectionReason;

  /// The staff member's activation status: "ACTIVE", "INACTIVE", "INVITE", etc.
  final String? memberStatus;

  /// Whether earning settings feature is enabled on this profile.
  final bool earningSettingsEnabled;

  /// Whether earning settings have been configured at least once.
  final bool earningSettingsConfigured;

  /// Whether loyalty (redemption) settings feature is enabled on this profile.
  final bool loyaltySettingsEnabled;

  /// Whether loyalty (redemption) settings have been configured at least once.
  final bool loyaltySettingsConfigured;

  bool get isStaffInactive => memberStatus?.toUpperCase() == 'INACTIVE';
  bool get hasPendingInvitation => !invitationAccepted;
}

/// Authenticated user returned after login.
class AuthUser {
  const AuthUser({
    required this.userId,
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

  final int userId;
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

  /// Multi-role/business check.
  bool get canSwitchRoles => (roles.length + businessProfiles.length) > 1;

  AuthUser copyWith({
    int? userId,
    String? token,
    String? tokenType,
    String? refreshToken,
    Set<UserRole>? roles,
    bool? emailVerified,
    bool? customerProfileComplete,
    bool? alreadyVerified,
    bool? hasMultipleRoles,
    List<BusinessProfileInfo>? businessProfiles,
  }) {
    return AuthUser(
      userId: userId ?? this.userId,
      token: token ?? this.token,
      tokenType: tokenType ?? this.tokenType,
      refreshToken: refreshToken ?? this.refreshToken,
      roles: roles ?? this.roles,
      emailVerified: emailVerified ?? this.emailVerified,
      customerProfileComplete:
          customerProfileComplete ?? this.customerProfileComplete,
      alreadyVerified: alreadyVerified ?? this.alreadyVerified,
      hasMultipleRoles: hasMultipleRoles ?? this.hasMultipleRoles,
      businessProfiles: businessProfiles ?? this.businessProfiles,
    );
  }

  /// Returns true if the user has at least one active business profile.
  bool get hasActiveBusinessProfiles =>
      businessProfiles.any((profile) => profile.active);

  /// Returns IDs of active business profiles.
  List<int> get activeBusinessIds =>
      businessProfiles.where((p) => p.active).map((p) => p.businessId).toList();
}
