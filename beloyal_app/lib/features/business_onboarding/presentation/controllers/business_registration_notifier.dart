import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/repositories/business_onboarding_api.dart';
import '../../data/models/business_registration_dto.dart';
import '../../data/models/register_user_dto.dart';
import '../../data/models/submit_application_models.dart';
import '../../data/models/verify_ownership_models.dart';
import './business_registration_draft.dart';

/// StateNotifier managing business registration draft state.
final businessRegistrationDraftProvider =
    StateNotifierProvider<
      BusinessRegistrationDraftNotifier,
      BusinessRegistrationDraft
    >((ref) => BusinessRegistrationDraftNotifier());

class BusinessRegistrationDraftNotifier
    extends StateNotifier<BusinessRegistrationDraft> {
  BusinessRegistrationDraftNotifier()
    : super(const BusinessRegistrationDraft());

  void setOwnerMode(OwnerMode mode) {
    state = state.copyWith(ownerMode: mode);
  }

  void setOwnershipToken(String token) {
    state = state.copyWith(ownershipToken: token);
  }

  void setNewUserDto(RegisterUserDto dto) {
    state = state.copyWith(newUserDto: dto);
  }

  void setBusinessRegistrationDto(BusinessRegistrationDto dto) {
    state = state.copyWith(businessRegistrationDto: dto);
  }

  void clear() {
    state = state.clear();
  }
}

/// AsyncNotifier for verifying existing account ownership.
final verifyOwnershipNotifierProvider =
    AsyncNotifierProvider<VerifyOwnershipNotifier, VerifyOwnershipResponse?>(
      VerifyOwnershipNotifier.new,
    );

class VerifyOwnershipNotifier extends AsyncNotifier<VerifyOwnershipResponse?> {
  @override
  Future<VerifyOwnershipResponse?> build() async => null;

  Future<void> verify(String email, String password) async {
    state = const AsyncLoading();

    try {
      final api = ref.read(businessOnboardingApiProvider);
      final response = await api.verifyOwnership(
        email: email,
        password: password,
      );

      // Update draft state with ownership token
      if (response.approved && response.ownershipToken.isNotEmpty) {
        ref.read(businessRegistrationDraftProvider.notifier)
          ..setOwnerMode(OwnerMode.EXISTING_AUTHENTICATED)
          ..setOwnershipToken(response.ownershipToken);
      }

      state = AsyncData(response);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// AsyncNotifier for submitting business application.
final submitBusinessApplicationNotifierProvider =
    AsyncNotifierProvider<
      SubmitBusinessApplicationNotifier,
      SubmitBusinessApplicationResponse?
    >(SubmitBusinessApplicationNotifier.new);

class SubmitBusinessApplicationNotifier
    extends AsyncNotifier<SubmitBusinessApplicationResponse?> {
  @override
  Future<SubmitBusinessApplicationResponse?> build() async => null;

  Future<void> submit() async {
    final draft = ref.read(businessRegistrationDraftProvider);

    if (!draft.isReadyForSubmission) {
      state = AsyncError(
        Exception('Draft is not ready for submission'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      final api = ref.read(businessOnboardingApiProvider);
      final response = await api.submitBusinessApplication(
        businessRegistrationDto: draft.businessRegistrationDto!,
        ownerMode: draft.ownerMode!,
        ownershipToken: draft.ownershipToken,
        userDto: draft.newUserDto,
      );

      // Clear draft on success
      if (response.success) {
        ref.read(businessRegistrationDraftProvider.notifier).clear();
      }

      state = AsyncData(response);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }

  void reset() {
    state = const AsyncData(null);
  }
}

/// AsyncNotifier for refreshing business status.
final refreshBusinessStatusNotifierProvider =
    AsyncNotifierProvider<RefreshBusinessStatusNotifier, BusinessStatus?>(
      RefreshBusinessStatusNotifier.new,
    );

class RefreshBusinessStatusNotifier extends AsyncNotifier<BusinessStatus?> {
  @override
  Future<BusinessStatus?> build() async => null;

  Future<void> refresh(int businessId) async {
    state = const AsyncLoading();

    try {
      final api = ref.read(businessOnboardingApiProvider);
      final data = await api.getBusinessStatus(businessId);

      final statusStr =
          data['businessStatus'] as String? ?? data['status'] as String?;
      final status = BusinessStatus.fromString(statusStr);

      state = AsyncData(status);
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
    }
  }
}
