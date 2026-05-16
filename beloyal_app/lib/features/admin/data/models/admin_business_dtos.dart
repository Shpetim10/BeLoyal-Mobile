// ── Platform Users DTOs ──────────────────────────────────────────────────────

class BusinessMembershipSummaryDto {
  BusinessMembershipSummaryDto({
    required this.businessId,
    required this.businessName,
    required this.role,
    required this.memberStatus,
  });

  factory BusinessMembershipSummaryDto.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return v.toString();
    }

    return BusinessMembershipSummaryDto(
      businessId: (json['businessId'] as num?)?.toInt() ?? 0,
      businessName: s(json['businessName']) ?? '',
      role: s(json['role']) ?? '',
      memberStatus: s(json['memberStatus']) ?? '',
    );
  }

  final int businessId;
  final String businessName;
  final String role;
  final String memberStatus;
}

class LoyaltySummaryDto {
  LoyaltySummaryDto({
    required this.totalEarned,
    required this.totalSpent,
    required this.totalExpired,
    required this.availablePoints,
    required this.businessCount,
  });

  factory LoyaltySummaryDto.fromJson(Map<String, dynamic> json) {
    int i(dynamic v) => (v as num?)?.toInt() ?? 0;
    return LoyaltySummaryDto(
      totalEarned: i(json['totalEarned']),
      totalSpent: i(json['totalSpent']),
      totalExpired: i(json['totalExpired']),
      availablePoints: i(json['availablePoints']),
      businessCount: i(json['businessCount']),
    );
  }

  final int totalEarned;
  final int totalSpent;
  final int totalExpired;
  final int availablePoints;
  final int businessCount;
}

class PlatformUserSummaryDto {
  PlatformUserSummaryDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.roles,
    required this.status,
    required this.emailVerified,
    this.lastLoginAt,
    this.createdAt,
    required this.businessMemberships,
    this.loyaltySummary,
  });

  factory PlatformUserSummaryDto.fromJson(Map<String, dynamic> json) {
    String? s(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return v.toString();
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is List && v.isNotEmpty) {
        return DateTime(
          v.isNotEmpty ? (v[0] as num).toInt() : 1970,
          v.length > 1 ? (v[1] as num).toInt() : 1,
          v.length > 2 ? (v[2] as num).toInt() : 1,
          v.length > 3 ? (v[3] as num).toInt() : 0,
          v.length > 4 ? (v[4] as num).toInt() : 0,
          v.length > 5 ? (v[5] as num).toInt() : 0,
        );
      }
      return null;
    }

    List<String> parseRoles(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [v.toString()];
    }

    return PlatformUserSummaryDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: s(json['firstName']) ?? '',
      lastName: s(json['lastName']) ?? '',
      username: s(json['username']) ?? '',
      email: s(json['email']) ?? '',
      phoneNumber: s(json['phoneNumber']),
      roles: parseRoles(json['roles']),
      status: s(json['status']) ?? 'UNKNOWN',
      emailVerified: (json['emailVerified'] as bool?) ?? false,
      lastLoginAt: parseDate(json['lastLoginAt']),
      createdAt: parseDate(json['createdAt']),
      businessMemberships: (json['businessMemberships'] as List?)
              ?.map((e) =>
                  BusinessMembershipSummaryDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loyaltySummary: json['loyaltySummary'] != null
          ? LoyaltySummaryDto.fromJson(
              json['loyaltySummary'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final List<String> roles;
  final String status;
  final bool emailVerified;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final List<BusinessMembershipSummaryDto> businessMemberships;
  final LoyaltySummaryDto? loyaltySummary;

  String get fullName => '$firstName $lastName'.trim();
  bool get isCustomer => roles.any((r) => r.toUpperCase().contains('CUSTOMER'));
  bool get isSuperAdmin => roles.any((r) => r.toUpperCase().contains('SUPER_ADMIN'));
}

// ── Business List / Details DTOs ─────────────────────────────────────────────

class BusinessListViewDto {
  BusinessListViewDto({
    required this.id,
    required this.businessName,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessEmail,
    required this.businessStatus,
    this.logoPath,
  });

  factory BusinessListViewDto.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return v.toString();
    }

    return BusinessListViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: parseString(json['businessName']) ?? 'Unknown Business',
      businessAddress:
          parseString(json['businessAddress']) ?? 'No address provided',
      businessPhone: parseString(json['businessPhone']) ?? 'No phone',
      businessEmail: parseString(json['businessEmail']) ?? 'No email',
      businessStatus: parseString(json['businessStatus']) ?? 'UNKNOWN',
      logoPath: parseString(json['logoPath']),
    );
  }

  final int id;
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessStatus;
  final String? logoPath;
}

class BusinessMemberDetailsDto {
  BusinessMemberDetailsDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.lastLogin,
    required this.role,
    this.hireDate,
    required this.memberStatus,
  });

  factory BusinessMemberDetailsDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is List && v.isNotEmpty) {
        final int year = v.isNotEmpty ? (v[0] as num).toInt() : 1970;
        final int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        final int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        final int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        final int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        final int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    String? parseString(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return v.toString();
    }

    return BusinessMemberDetailsDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: parseString(json['firstName']) ?? '',
      lastName: parseString(json['lastName']) ?? '',
      email: parseString(json['email']) ?? '',
      lastLogin: parseDate(json['lastLogin']),
      role: parseString(json['role']) ?? 'UNKNOWN',
      hireDate: parseDate(json['hireDate']),
      memberStatus: parseString(json['memberStatus']) ?? 'UNKNOWN',
    );
  }

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final DateTime? lastLogin;
  final String role;
  final DateTime? hireDate;
  final String memberStatus;

  String get fullName => '$firstName $lastName'.trim();
}

class BusinessDetailsDto {
  BusinessDetailsDto({
    required this.id,
    required this.businessName,
    required this.businessType,
    required this.businessDescription,
    this.logoPath,
    required this.address,
    required this.city,
    required this.country,
    this.vatId,
    this.currencyCode,
    required this.businessPhoneNumber,
    required this.businessStatus,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.businessMembers,
  });

  factory BusinessDetailsDto.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is List && v.isNotEmpty) {
        final int year = v.isNotEmpty ? (v[0] as num).toInt() : 1970;
        final int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        final int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        final int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        final int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        final int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    String? parseString(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      return v.toString();
    }

    return BusinessDetailsDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: parseString(json['businessName']) ?? 'Unknown',
      businessType: parseString(json['businessType']) ?? '',
      businessDescription: parseString(json['businessDescription']) ?? '',
      logoPath: parseString(json['logoPath']),
      address: parseString(json['address']) ?? '',
      city: parseString(json['city']) ?? '',
      country: parseString(json['country']) ?? '',
      vatId: parseString(json['vatId']),
      currencyCode:
          parseString(json['currency']) ?? parseString(json['currencyCode']),
      businessPhoneNumber: parseString(json['businessPhoneNumber']) ?? '',
      businessStatus: parseString(json['businessStatus']) ?? 'UNKNOWN',
      submittedAt: parseDate(json['submittedAt']),
      reviewedAt: parseDate(json['reviewedAt']),
      rejectionReason: parseString(json['rejectionReason']),
      businessMembers: (json['businessMembers'] as List?)
              ?.map((e) => BusinessMemberDetailsDto.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final int id;
  final String businessName;
  final String businessType;
  final String businessDescription;
  final String? logoPath;
  final String address;
  final String city;
  final String country;
  final String? vatId;
  final String? currencyCode;
  final String businessPhoneNumber;
  final String businessStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<BusinessMemberDetailsDto> businessMembers;
}
