import '../../../business_onboarding/models/business_registration_dto.dart';
import '../../../business_onboarding/models/submit_application_models.dart';

/// Represents a business application submitted for review by the Super Admin.
class BusinessApplication {
  const BusinessApplication({
    required this.id,
    required this.businessName,
    required this.businessType,
    this.businessDescription,
    this.logoPath,
    this.address,
    required this.city,
    this.country,
    this.websiteUrl,
    required this.vatId,
    this.rating = 0.0,
    this.businessPhoneNumber,
    required this.businessEmail,
    required this.businessStatus,
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    this.reviewedByAdminId,
    this.owner,
  });

  factory BusinessApplication.fromJson(Map<String, dynamic> json) {
    return BusinessApplication(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: (json['businessName'] as String?) ?? 'Unnamed Business',
      businessType: BusinessType.values.firstWhere(
        (e) => e.value == json['businessType'],
        orElse: () => BusinessType.OTHER,
      ),
      businessDescription: json['businessDescription'] as String?,
      logoPath: json['logoPath'] as String?,
      address: json['address'] as String?,
      city: (json['city'] as String?) ?? 'Unknown City',
      country: json['country'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      vatId: (json['vatId'] as String?) ?? 'N/A',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      businessPhoneNumber: json['businessPhoneNumber'] as String?,
      businessEmail: (json['businessEmail'] as String?) ?? 'No Email',
      businessStatus:
          BusinessStatus.fromString(json['businessStatus'] as String?) ??
          BusinessStatus.pendingApproval,
      submittedAt: json['submittedAt'] != null
          ? DateTime.tryParse(json['submittedAt'] as String)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      rejectionReason: json['rejectionReason'] as String?,
      reviewedByAdminId: (json['reviewedByAdminId'] as num?)?.toInt(),
      owner: json['owner'] != null
          ? ApplicationOwner.fromJson(json['owner'] as Map<String, dynamic>)
          : null,
    );
  }

  final int id;
  final String businessName;
  final BusinessType businessType;
  final String? businessDescription;
  final String? logoPath;
  final String? address;
  final String city;
  final String? country;
  final String? websiteUrl;
  final String vatId;
  final double rating;
  final String? businessPhoneNumber;
  final String businessEmail;
  final BusinessStatus businessStatus;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final int? reviewedByAdminId;
  final ApplicationOwner? owner;

  /// Displayable full location. Falls back gracefully.
  String get location {
    final parts = [city, country].where((s) => s != null && s.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(', ');
  }

  /// Contact string logic.
  String get contactInfo {
    final hasPhone =
        businessPhoneNumber != null && businessPhoneNumber!.isNotEmpty;
    if (hasPhone) return '$businessPhoneNumber • $businessEmail';
    return businessEmail;
  }
}

/// Owner details nested within a generic business application fetch
class ApplicationOwner {
  final int? id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phoneNumber;
  final String? status;
  final DateTime? lastLoginAt;

  const ApplicationOwner({
    this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phoneNumber,
    this.status,
    this.lastLoginAt,
  });

  factory ApplicationOwner.fromJson(Map<String, dynamic> json) {
    return ApplicationOwner(
      id: (json['id'] as num?)?.toInt(),
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      status: json['status'] as String?,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.tryParse(json['lastLoginAt'] as String)
          : null,
    );
  }

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'N/A' : combined;
  }
}
