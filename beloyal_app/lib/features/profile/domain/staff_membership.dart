import '../../staff/domain/models/staff_member.dart'; // For MemberStatus enum

/// Represents the logged-in staff user's own membership details
/// for a specific business.
class StaffMembership {
  const StaffMembership({
    required this.businessId,
    required this.businessName,
    required this.role,
    this.hireDate,
    this.lastLogin,
    required this.memberStatus,
  });

  final int businessId;
  final String businessName;
  final String role;
  final DateTime? hireDate;
  final DateTime? lastLogin;
  final MemberStatus memberStatus;

  factory StaffMembership.fromJson(Map<String, dynamic> json) {
    var bName = '';
    var bId = 0;

    // Sometimes backend nests business info, sometimes it's flat
    if (json.containsKey('business') && json['business'] != null) {
      final biz = json['business'] as Map<String, dynamic>;
      bId = (biz['id'] as num?)?.toInt() ?? 0;
      bName = biz['businessName'] as String? ?? '';
    } else {
      bId = (json['businessId'] as num?)?.toInt() ?? 0;
      bName = json['businessName'] as String? ?? '';
    }

    return StaffMembership(
      businessId: bId,
      businessName: bName,
      role: json['role'] as String? ?? 'STAFF',
      hireDate: json['hireDate'] != null
          ? DateTime.tryParse(json['hireDate'] as String)
          : null,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'] as String)
          : null,
      memberStatus: MemberStatus.fromBackend(
        (json['memberStatus'] as String?) ?? 'INACTIVE',
      ),
    );
  }

  StaffMembership copyWith({
    int? businessId,
    String? businessName,
    String? role,
    DateTime? hireDate,
    DateTime? lastLogin,
    MemberStatus? memberStatus,
  }) {
    return StaffMembership(
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      role: role ?? this.role,
      hireDate: hireDate ?? this.hireDate,
      lastLogin: lastLogin ?? this.lastLogin,
      memberStatus: memberStatus ?? this.memberStatus,
    );
  }
}
