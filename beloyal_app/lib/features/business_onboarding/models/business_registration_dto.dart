/// Business registration data transfer object matching backend expectations.
class BusinessRegistrationDto {
  const BusinessRegistrationDto({
    required this.businessName,
    required this.businessType,
    this.address,
    required this.city,
    this.country,
    required this.businessEmail,
    required this.businessPhoneNumber,
    this.vatId,
    this.websiteUrl,
    this.logoUrl,
    this.businessDescription,
  });

  final String businessName;
  final String businessType; // Restaurant, Café, Bar, Other
  final String? address;
  final String city;
  final String? country;
  final String businessEmail;
  final String businessPhoneNumber;
  final String? vatId;
  final String? websiteUrl;
  final String? logoUrl;
  final String? businessDescription;

  Map<String, dynamic> toJson() => {
        'businessName': businessName.trim(),
        'businessType': businessType,
        if (address != null && address!.isNotEmpty) 'address': address!.trim(),
        'city': city.trim(),
        if (country != null && country!.isNotEmpty) 'country': country!.trim(),
        'businessEmail': businessEmail.trim().toLowerCase(),
        'businessPhoneNumber': businessPhoneNumber.trim(),
        if (vatId != null && vatId!.isNotEmpty) 'vatId': vatId!.trim(),
        if (websiteUrl != null && websiteUrl!.isNotEmpty)
          'websiteUrl': websiteUrl!.trim(),
        if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl!.trim(),
        if (businessDescription != null && businessDescription!.isNotEmpty)
          'businessDescription': businessDescription!.trim(),
      };
}

/// Business type enum for dropdown selection.
enum BusinessType {
  RESTAURANT('Restaurant', 'RESTAURANT'),
  CAFE('Café', 'CAFE'),
  BAR('Bar', 'BAR'),
  FAST_FOOD('Fast Food', 'FAST_FOOD'),
  PUB('Pub', 'PUB'),
  OTHER("Other", 'OTHER');

  const BusinessType(this.displayName, this.value);
  final String displayName;
  final String value;
}
