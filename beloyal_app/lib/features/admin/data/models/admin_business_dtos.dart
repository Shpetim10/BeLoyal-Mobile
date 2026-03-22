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
    return BusinessListViewDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: json['businessName']?.toString() ?? 'Unknown Business',
      businessAddress: json['businessAddress']?.toString() ?? 'No address provided',
      businessPhone: json['businessPhone']?.toString() ?? 'No phone',
      businessEmail: json['businessEmail']?.toString() ?? 'No email',
      businessStatus: json['businessStatus']?.toString() ?? 'UNKNOWN',
      logoPath: json['logoPath']?.toString(),
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
        int year = v.length > 0 ? (v[0] as num).toInt() : 1970;
        int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    return BusinessMemberDetailsDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      lastLogin: parseDate(json['lastLogin']),
      role: json['role']?.toString() ?? 'UNKNOWN',
      hireDate: parseDate(json['hireDate']),
      memberStatus: json['memberStatus']?.toString() ?? 'UNKNOWN',
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
        int year = v.length > 0 ? (v[0] as num).toInt() : 1970;
        int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    return BusinessDetailsDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: json['businessName']?.toString() ?? 'Unknown',
      businessType: json['businessType']?.toString() ?? '',
      businessDescription: json['businessDescription']?.toString() ?? '',
      logoPath: json['logoPath']?.toString(),
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      vatId: json['vatId']?.toString(),
      businessPhoneNumber: json['businessPhoneNumber']?.toString() ?? '',
      businessStatus: json['businessStatus']?.toString() ?? 'UNKNOWN',
      submittedAt: parseDate(json['submittedAt']),
      reviewedAt: parseDate(json['reviewedAt']),
      rejectionReason: json['rejectionReason']?.toString(),
      businessMembers: (json['businessMembers'] as List?)
              ?.map((e) => BusinessMemberDetailsDto.fromJson(e as Map<String, dynamic>))
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
  final String businessPhoneNumber;
  final String businessStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final List<BusinessMemberDetailsDto> businessMembers;
}
