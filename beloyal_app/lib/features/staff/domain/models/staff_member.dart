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
    final parts = [
      firstName,
      lastName,
    ].map((s) => s?.trim()).where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  /// 1-2 character initials for the avatar.
  String get initials {
    final f = (firstName?.trim().isNotEmpty == true)
        ? firstName!.trim()[0]
        : '';
    final l = (lastName?.trim().isNotEmpty == true) ? lastName!.trim()[0] : '';
    final result = '$f$l'.trim().toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    // Helper to parse dates that might come as a list [year, month, day, ...]
    // or as a standard ISO string.
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      if (d is String) return DateTime.tryParse(d);
      if (d is List && d.isNotEmpty) {
        final parts = d.cast<int>();
        return DateTime(
          parts.elementAtOrNull(0) ?? 1970,
          parts.elementAtOrNull(1) ?? 1,
          parts.elementAtOrNull(2) ?? 1,
          parts.elementAtOrNull(3) ?? 0,
          parts.elementAtOrNull(4) ?? 0,
          parts.elementAtOrNull(5) ?? 0,
        );
      }
      return null;
    }

    return StaffMember(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      lastLogin: parseDate(json['lastLogin']),
      role: (json['role'] as String?) ?? 'STAFF',
      hireDate: parseDate(json['hireDate']),
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
