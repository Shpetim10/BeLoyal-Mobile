/// Business registration data transfer object matching backend expectations.
class BusinessRegistrationDto {
  const BusinessRegistrationDto({
    required this.businessName,
    required this.businessType,
    required this.currency,
    this.address,
    required this.city,
    this.country,
    required this.businessEmail,
    required this.businessPhoneNumber,
    this.vatId,
    this.websiteUrl,
    this.logoUrl,
    this.logoKey,
    this.businessDescription,
  });

  final String businessName;
  final String businessType;
  /// ISO 4217 currency code used for all money amounts in this business.
  /// Mandatory at registration. Allowed values: ALL, EUR, USD.
  final String currency;
  final String? address;
  final String city;
  final String? country;
  final String businessEmail;
  final String businessPhoneNumber;
  final String? vatId;
  final String? websiteUrl;
  final String? logoUrl;
  final String? logoKey;
  final String? businessDescription;

  Map<String, dynamic> toJson() => {
    'businessName': businessName.trim(),
    'businessType': businessType,
    'currency': currency,
    if (address != null && address!.isNotEmpty) 'address': address!.trim(),
    'city': city.trim(),
    if (country != null && country!.isNotEmpty) 'country': country!.trim(),
    'businessEmail': businessEmail.trim().toLowerCase(),
    'businessPhoneNumber': businessPhoneNumber.trim(),
    if (vatId != null && vatId!.isNotEmpty) 'vatId': vatId!.trim(),
    if (websiteUrl != null && websiteUrl!.isNotEmpty)
      'websiteUrl': websiteUrl!.trim(),
    if (logoUrl != null && logoUrl!.isNotEmpty) 'logoUrl': logoUrl!.trim(),
    if (logoKey != null && logoKey!.isNotEmpty) 'logoKey': logoKey!.trim(),
    if (businessDescription != null && businessDescription!.isNotEmpty)
      'businessDescription': businessDescription!.trim(),
  };
}

/// Supported currencies for business registration.
/// Maps to [BusinessCurrency] in lib/core/utils/currency_utils.dart.
enum RegistrationCurrency {
  lek('Albanian Lek (ALL)', 'ALL'),
  euro('Euro (€)', 'EUR'),
  dollar('US Dollar (\$)', 'USD');

  const RegistrationCurrency(this.displayName, this.code);
  final String displayName;
  final String code;
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
