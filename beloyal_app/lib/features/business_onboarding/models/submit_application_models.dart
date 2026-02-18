import 'business_registration_dto.dart';
import 'register_user_dto.dart';

/// Request payload for submitting business application.
/// Backend expects either:
/// - { businessRegistrationDto, ownershipToken } for existing users
/// - { businessRegistrationDto, userDto } for new users
class SubmitBusinessApplicationRequest {
  const SubmitBusinessApplicationRequest({
    required this.businessRegistrationDto,
    required this.ownerMode,
    this.ownershipToken,
    this.userDto,
  }) : assert(
          (ownershipToken != null) != (userDto != null),
          'Either ownershipToken or userDto must be provided, but not both',
        );

  final BusinessRegistrationDto businessRegistrationDto;
  final OwnerMode ownerMode;
  final String? ownershipToken; // For existing authenticated users
  final RegisterUserDto? userDto; // For new account creation

  Map<String, dynamic> toJson() => {
        'businessRegistrationDto': businessRegistrationDto.toJson(),
        'ownerMode': ownerMode.value,
        if (ownershipToken != null) 'ownershipToken': ownershipToken,
        if (userDto != null) 'userDto': userDto!.toJson(),
      };
}

/// Response model from business application submission.
class SubmitBusinessApplicationResponse {
  const SubmitBusinessApplicationResponse({
    required this.success,
    this.message,
    this.businessId,
    this.businessName,
    this.status,
  });

  factory SubmitBusinessApplicationResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubmitBusinessApplicationResponse(
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      businessId: json['businessId'] as int?,
      businessName: json['businessName'] as String?,
      status: json['status'] as String?,
    );
  }

  final bool success;
  final String? message;
  final int? businessId;
  final String? businessName;
  final String? status; // PENDING_APPROVAL, ACTIVE, etc.
}

/// Business status enum for client-side status checks.
enum BusinessStatus {
  pendingApproval('PENDING_APPROVAL'),
  active('ACTIVE'),
  rejected('REJECTED'),
  inactive('INACTIVE');

  const BusinessStatus(this.value);
  final String value;

  static BusinessStatus? fromString(String? value) {
    if (value == null) return null;
    return BusinessStatus.values.firstWhere(
      (e) => e.value == value.toUpperCase(),
      orElse: () => BusinessStatus.pendingApproval,
    );
  }
}

enum OwnerMode{
  NEW_ACCOUNT("NEW_ACCOUNT"),
  EXISTING_AUTHENTICATED("EXISTING_AUTHENTICATED");

  const OwnerMode(this.value);

  final String value;
}
