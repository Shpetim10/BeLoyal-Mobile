class CustomerProfile {
  const CustomerProfile({
    this.city,
    this.country,
    this.gender,
    this.birthdate,
    this.referralCode,
    this.referredBy,
  });

  final String? city;
  final String? country;
  final String? gender;
  final DateTime? birthdate;
  final String? referralCode;
  final String? referredBy;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parsedBirthdate;
    final birthdateStr = json['birthDate'] ?? json['birthdate'];
    if (birthdateStr != null && birthdateStr is String) {
      parsedBirthdate = DateTime.tryParse(birthdateStr);
    }

    return CustomerProfile(
      city: json['city'] as String?,
      country: json['country'] as String?,
      gender: json['gender'] as String?,
      birthdate: parsedBirthdate,
      referralCode: json['referralCode'] as String?,
      referredBy: json['referredBy'] as String?,
    );
  }

  CustomerProfile copyWith({
    String? city,
    String? country,
    String? gender,
    DateTime? birthdate,
    String? referralCode,
    String? referredBy,
    bool clearCity = false,
    bool clearCountry = false,
    bool clearGender = false,
    bool clearBirthdate = false,
  }) {
    return CustomerProfile(
      city: clearCity ? null : (city ?? this.city),
      country: clearCountry ? null : (country ?? this.country),
      gender: clearGender ? null : (gender ?? this.gender),
      birthdate: clearBirthdate ? null : (birthdate ?? this.birthdate),
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
    );
  }
}
