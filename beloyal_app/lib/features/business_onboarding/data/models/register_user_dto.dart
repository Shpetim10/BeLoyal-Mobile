/// User registration DTO for new account creation during business onboarding.
/// Matches the structure expected by backend for user registration.
class RegisterUserDto {
  const RegisterUserDto({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    this.phoneNumber,
    required this.password,
    required this.acceptedTc,
    required this.acceptedTcVersion,
  });

  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String password;
  final bool acceptedTc;
  final String acceptedTcVersion;

  Map<String, dynamic> toJson() => {
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        if (phoneNumber != null && phoneNumber!.isNotEmpty)
          'phoneNumber': phoneNumber!.trim(),
        'password': password,
        'acceptedTc': acceptedTc,
        'acceptedTcVersion': acceptedTcVersion,
      };
}
