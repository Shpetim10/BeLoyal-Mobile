/// Status of a business membership.
enum MemberStatus {
  active,
  inactive,
  invited;

  /// Backend sends uppercase strings ("ACTIVE", "INACTIVE", "INVITED" or
  /// "PENDING_ACCEPTANCE"). Normalise them here.
  static MemberStatus fromBackend(String raw) {
    final upper = raw.toUpperCase().trim();
    return switch (upper) {
      'ACTIVE' => MemberStatus.active,
      'INACTIVE' => MemberStatus.inactive,
      'INVITED' || 'PENDING_ACCEPTANCE' || 'INVITE' => MemberStatus.invited,
      _ => MemberStatus.inactive,
    };
  }

  /// Label shown in the UI badge.
  String get label => switch (this) {
    MemberStatus.active => 'Active',
    MemberStatus.inactive => 'Inactive',
    MemberStatus.invited => 'Invited',
  };

  /// Value sent to the backend PATCH endpoint.
  String get backendValue => switch (this) {
    MemberStatus.active => 'ACTIVE',
    MemberStatus.inactive => 'INACTIVE',
    MemberStatus.invited => 'INVITE',
  };
}

/// A single staff member returned by **GET /business/{id}/staff**.
class StaffMember {
  const StaffMember({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.lastLogin,
    this.role = 'STAFF',
    this.hireDate,
    required this.memberStatus,
  });

  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final DateTime? lastLogin;
  final String role;
  final DateTime? hireDate;
  final MemberStatus memberStatus;

  /// Displayable full name. Falls back to "—" when both are null.
  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  /// 1-2 character initials for the avatar.
  String get initials {
    final f = (firstName?.isNotEmpty == true) ? firstName![0] : '';
    final l = (lastName?.isNotEmpty == true) ? lastName![0] : '';
    final result = '$f$l'.trim().toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  // ── JSON helpers ──

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'] as String)
          : null,
      role: (json['role'] as String?) ?? 'STAFF',
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'] as String)
          : null,
      memberStatus: MemberStatus.fromBackend(
        (json['memberStatus'] as String?) ?? 'INACTIVE',
      ),
    );
  }

  /// Returns a copy with a different status (for optimistic UI).
  StaffMember copyWith({MemberStatus? memberStatus}) {
    return StaffMember(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      lastLogin: lastLogin,
      role: role,
      hireDate: hireDate,
      memberStatus: memberStatus ?? this.memberStatus,
    );
  }
}
