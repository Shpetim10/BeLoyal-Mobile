/// Request model for verifying existing account ownership.
class VerifyOwnershipRequest {
  const VerifyOwnershipRequest({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {
        'email': email.trim().toLowerCase(),
        'password': password,
      };
}

/// Response model from verify-ownership endpoint.
class VerifyOwnershipResponse {
  const VerifyOwnershipResponse({
    required this.approved,
    required this.emailVerified,
    required this.ownershipToken,
  });

  factory VerifyOwnershipResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOwnershipResponse(
      approved: json['approved'] as bool? ?? false,
      emailVerified: json['emailVerified'] as bool? ?? false,
      ownershipToken: json['ownershipToken'] as String? ?? '',
    );
  }

  final bool approved;
  final bool emailVerified;
  final String ownershipToken;
}
