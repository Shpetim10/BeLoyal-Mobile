import '../../data/models/business_registration_dto.dart';
import '../../data/models/register_user_dto.dart';
import '../../data/models/submit_application_models.dart';

/// Draft state for business registration (multi-step form).
class BusinessRegistrationDraft {
  const BusinessRegistrationDraft({
    this.ownerMode,
    this.ownershipToken,
    this.newUserDto,
    this.businessRegistrationDto,
  });

  final OwnerMode? ownerMode;
  final String? ownershipToken; // Set after verifying existing account
  final RegisterUserDto? newUserDto; // Set when creating new account
  final BusinessRegistrationDto? businessRegistrationDto;

  BusinessRegistrationDraft copyWith({
    OwnerMode? ownerMode,
    String? ownershipToken,
    RegisterUserDto? newUserDto,
    BusinessRegistrationDto? businessRegistrationDto,
  }) {
    return BusinessRegistrationDraft(
      ownerMode: ownerMode ?? this.ownerMode,
      ownershipToken: ownershipToken ?? this.ownershipToken,
      newUserDto: newUserDto ?? this.newUserDto,
      businessRegistrationDto:
          businessRegistrationDto ?? this.businessRegistrationDto,
    );
  }

  /// Check if draft is ready for submission.
  bool get isReadyForSubmission {
    if (businessRegistrationDto == null) return false;
    if (ownerMode == OwnerMode.EXISTING_AUTHENTICATED) {
      return ownershipToken != null && ownershipToken!.isNotEmpty;
    }
    if (ownerMode == OwnerMode.NEW_ACCOUNT) {
      return newUserDto != null;
    }
    return false;
  }

  /// Clear all draft data (after successful submission).
  BusinessRegistrationDraft clear() {
    return const BusinessRegistrationDraft();
  }
}
