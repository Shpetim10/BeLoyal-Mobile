/// Client-side validators mirroring Spring Boot's @ValidEmail, @ValidPassword, etc.
abstract final class Validators {
  static final _emailRegex = RegExp(r'^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,}$');
  static final _phoneRegex = RegExp(r'^\+?[0-9\s\-()]{7,15}$');
  static final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (value.length > 255) return 'Email is too long';
    if (!_emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
    return null;
  }
  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length > 128) return 'Password is too long';
    if (value.length < 8) return 'At least 8 characters';
    if (!_passwordRegex.hasMatch(value)) {
      return 'Must include upper, lower, digit & special char';
    }
    return null;
  }

  /// Login password — less strict (just required, server handles the rest).
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    return null;
  }
  static String? Function(String?) confirmPassword(String password) {
    return (String? value) {
      if (value == null || value.isEmpty) return 'Please confirm password';
      if (value != password) return 'Passwords do not match';
      return null;
    };
  }
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    if (value.trim().length < 2) return 'At least 2 characters';
    if (value.trim().length > 100) return 'Too long';
    return null;
  }
  static String? username(String? value) {
    if (value == null || value.trim().isEmpty) return 'Username is required';
    if (value.trim().length < 3) return 'At least 3 characters';
    if (value.trim().length > 50) return 'Too long';
    return null;
  }
  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!_phoneRegex.hasMatch(value.trim()))
      return 'Enter a valid phone number';
    return null;
  }
}
