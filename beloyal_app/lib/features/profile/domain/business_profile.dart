import '../../business_onboarding/models/business_registration_dto.dart';
import '../../business_onboarding/models/submit_application_models.dart';

/// Business profile data for a registered business.
class BusinessProfile {
  const BusinessProfile({
    required this.id,
    required this.businessName,
    this.businessType,
    this.publicDescription,
    this.address,
    this.city,
    this.country,
    this.websiteUrl,
    this.vatId,
    this.contactEmail,
    this.contactPhone,
    this.logoPath,
    this.logoKey,
    this.status,
    this.rating = 0.0,
  });

  final int id;
  final String businessName;
  final BusinessType? businessType;
  final String? publicDescription;
  final String? address;
  final String? city;
  final String? country;
  final String? websiteUrl;
  final String? vatId;
  final String? contactEmail;
  final String? contactPhone;
  final String? logoPath;
  final String? logoKey;
  final BusinessStatus? status;
  final double rating;

  /// Returns color-coded status string for display.
  String get statusDisplay => status?.value ?? '—';

  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      businessName: json['businessName'] as String? ?? '',
      businessType: json['businessType'] != null
          ? BusinessType.values.firstWhere(
              (e) => e.value == json['businessType'],
              orElse: () => BusinessType.OTHER,
            )
          : null,
      publicDescription:
          json['businessDescription'] as String? ??
          json['publicDescription'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      websiteUrl: json['websiteUrl'] as String?,
      vatId: json['vatId'] as String?,
      contactEmail:
          json['businessEmail'] as String? ?? json['contactEmail'] as String?,
      contactPhone:
          json['businessPhoneNumber'] as String? ??
          json['contactPhone'] as String?,
      logoPath: json['logoPath'] as String?,
      logoKey: json['logoKey'] as String?,
      status: BusinessStatus.fromString(json['businessStatus'] as String?),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'businessName': businessName,
    if (businessType != null) 'businessType': businessType!.value,
    if (publicDescription != null) 'businessDescription': publicDescription,
    if (address != null) 'address': address,
    if (city != null) 'city': city,
    if (country != null) 'country': country,
    if (websiteUrl != null) 'websiteUrl': websiteUrl,
    if (vatId != null) 'vatId': vatId,
    if (contactEmail != null) 'businessEmail': contactEmail,
    if (contactPhone != null) 'businessPhoneNumber': contactPhone,
    if (logoPath != null) 'logoPath': logoPath,
    if (logoKey != null) 'logoKey': logoKey,
  };

  BusinessProfile copyWith({
    int? id,
    String? businessName,
    BusinessType? businessType,
    String? publicDescription,
    String? address,
    String? city,
    String? country,
    String? websiteUrl,
    String? vatId,
    String? contactEmail,
    String? contactPhone,
    String? logoPath,
    String? logoKey,
    BusinessStatus? status,
    double? rating,
    bool clearPublicDescription = false,
    bool clearAddress = false,
    bool clearWebsiteUrl = false,
    bool clearLogoPath = false,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      businessName: businessName ?? this.businessName,
      businessType: businessType ?? this.businessType,
      publicDescription: clearPublicDescription
          ? null
          : (publicDescription ?? this.publicDescription),
      address: clearAddress ? null : (address ?? this.address),
      city: city ?? this.city,
      country: country ?? this.country,
      websiteUrl: clearWebsiteUrl ? null : (websiteUrl ?? this.websiteUrl),
      vatId: vatId ?? this.vatId,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      logoPath: clearLogoPath ? null : (logoPath ?? this.logoPath),
      logoKey: clearLogoPath ? null : (logoKey ?? this.logoKey),
      status: status ?? this.status,
      rating: rating ?? this.rating,
    );
  }
}
