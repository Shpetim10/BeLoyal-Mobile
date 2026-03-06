/// DTO returned by the backend after a successful customer profile creation.
///
/// Maps to:
/// ```json
/// {
///   "firstName": "John",
///   "lastName":  "Smith",
///   "qrToken":   "a1b2c3d4...",
///   "manualCode": "BL-84X92K"
/// }
/// ```
class CustomerProfileCreationResponse {
  const CustomerProfileCreationResponse({
    required this.firstName,
    required this.lastName,
    required this.qrToken,
    required this.manualCode,
  });

  final String firstName;
  final String lastName;
  final String qrToken;
  final String manualCode;

  factory CustomerProfileCreationResponse.fromJson(Map<String, dynamic> json) {
    return CustomerProfileCreationResponse(
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      qrToken: (json['qrToken'] as String?) ?? '',
      manualCode: (json['manualCode'] as String?) ?? '',
    );
  }
}
