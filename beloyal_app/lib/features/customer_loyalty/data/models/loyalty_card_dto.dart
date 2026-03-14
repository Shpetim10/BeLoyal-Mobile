/// Data returned by GET /api/besahub/customer/me/loyalty-card
class LoyaltyCardDto {
  const LoyaltyCardDto({
    required this.firstName,
    required this.lastName,
    required this.qrToken,
    required this.manualCode,
  });

  final String firstName;
  final String lastName;
  final String qrToken;
  final String manualCode;

  factory LoyaltyCardDto.fromJson(Map<String, dynamic> json) {
    return LoyaltyCardDto(
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      qrToken: (json['qrToken'] as String?) ?? '',
      manualCode: (json['manualCode'] as String?) ?? '',
    );
  }
}
