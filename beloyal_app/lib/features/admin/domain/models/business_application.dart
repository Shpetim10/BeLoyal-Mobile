import '../../../business_onboarding/data/models/business_registration_dto.dart';
import '../../../business_onboarding/data/models/submit_application_models.dart';

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
      businessType: BusinessType.values.firstWhere((e) {
        final rawType = json['businessType'];
        if (rawType is List && rawType.isNotEmpty) {
          return e.value == rawType.first.toString();
        }
        return e.value == rawType?.toString();
      }, orElse: () => BusinessType.OTHER),
      businessDescription: _parseString(json['businessDescription']),
      logoPath: _parseString(json['logoPath']),
      address: _parseString(json['address']),
      city: _parseString(json['city']) ?? 'Unknown City',
      country: _parseString(json['country']),
      websiteUrl: _parseString(json['websiteUrl']),
      vatId: _parseString(json['vatId']) ?? 'N/A',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      businessPhoneNumber: _parseString(json['businessPhoneNumber']),
      businessEmail: _parseString(json['businessEmail']) ?? 'No Email',
      businessStatus:
          BusinessStatus.fromString(_parseString(json['businessStatus'])) ??
          BusinessStatus.pendingApproval,
      submittedAt: _parseDate(json['submittedAt']),
      reviewedAt: _parseDate(json['reviewedAt']),
      rejectionReason: _parseString(json['rejectionReason']),
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
      firstName: _parseString(json['firstName']),
      lastName: _parseString(json['lastName']),
      email: _parseString(json['email']),
      phoneNumber: _parseString(json['phoneNumber']),
      status: _parseString(json['status']),
      lastLoginAt: _parseDate(json['lastLoginAt']),
    );
  }

  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    final combined = '$first $last'.trim();
    return combined.isEmpty ? 'N/A' : combined;
  }
}

/// Helper to safely parse potentially list-wrapped strings
String? _parseString(dynamic value) {
  if (value == null) return null;
  if (value is List && value.isNotEmpty) return value.first.toString();
  return value.toString();
}

/// Helper to parse DateTimes, handling both ISO strings and Spring Boot LocalDateTime arrays
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String) return DateTime.tryParse(value);
  if (value is List && value.length >= 3) {
    try {
      final year = value[0] as int;
      final month = value[1] as int;
      final day = value[2] as int;
      final hour = value.length > 3 ? value[3] as int : 0;
      final minute = value.length > 4 ? value[4] as int : 0;
      final second = value.length > 5 ? value[5] as int : 0;
      return DateTime(year, month, day, hour, minute, second);
    } catch (_) {
      return null;
    }
  }
  return null;
}
