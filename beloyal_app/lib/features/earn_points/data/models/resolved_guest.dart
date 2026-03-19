/// A customer resolved from QR scan or manual search.
///
/// Maps to the backend response from:
///   GET /business/{id}/customers/lookup?loyaltyId=X
///   GET /business/{id}/customers/search?q=X
class ResolvedGuest {
  const ResolvedGuest({
    required this.customerId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.currentPoints,
  });

  final int customerId;
  final String firstName;
  final String lastName;
  final String email;
  final int currentPoints;

  String get fullName {
    final parts = [firstName, lastName]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    return parts.isEmpty ? '—' : parts.join(' ');
  }

  String get initials {
    final f = firstName.trim().isNotEmpty ? firstName.trim()[0] : '';
    final l = lastName.trim().isNotEmpty ? lastName.trim()[0] : '';
    final result = '$f$l'.trim().toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  factory ResolvedGuest.fromJson(Map<String, dynamic> json) {
    return ResolvedGuest(
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      firstName: (json['firstName'] as String?) ?? '',
      lastName: (json['lastName'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
      currentPoints: (json['currentPoints'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'customerId': customerId,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'currentPoints': currentPoints,
      };

  ResolvedGuest copyWith({
    int? customerId,
    String? firstName,
    String? lastName,
    String? email,
    int? currentPoints,
  }) {
    return ResolvedGuest(
      customerId: customerId ?? this.customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      currentPoints: currentPoints ?? this.currentPoints,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedGuest &&
          runtimeType == other.runtimeType &&
          customerId == other.customerId;

  @override
  int get hashCode => customerId.hashCode;
}
