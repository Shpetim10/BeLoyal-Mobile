class UserProfile {
  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    this.phoneNumber,
    this.profileImageUrl,
    this.profileImageKey,
    required this.acceptedTerms,
  });

  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final String username;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? profileImageKey;
  final bool acceptedTerms;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      userId: (json['userId'] ?? json['id']) as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      profileImageUrl:
          json['profileImage'] as String? ??
          json['imagePath'] as String? ??
          json['profileImageUrl'] as String?,
      profileImageKey:
          json['profileImageKey'] as String? ??
          json['imageKey'] as String? ??
          json['profileImageKey'] as String?,
      acceptedTerms: json['acceptedTerms'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    int? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? phoneNumber,
    String? profileImageUrl,
    String? profileImageKey,
    bool? acceptedTerms,
    bool clearPhoneNumber = false,
    bool clearProfileImageUrl = false,
  }) {
    return UserProfile(
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      phoneNumber: clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      profileImageUrl: clearProfileImageUrl
          ? null
          : (profileImageUrl ?? this.profileImageUrl),
      profileImageKey: clearProfileImageUrl
          ? null
          : (profileImageKey ?? this.profileImageKey),
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }
}
