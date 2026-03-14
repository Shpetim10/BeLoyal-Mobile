import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/repositories/business_onboarding_api.dart';
import '../../data/models/business_registration_dto.dart';
import '../../data/models/submit_application_models.dart';

/// Provider that fetches current registration data for a business (pre-fill).
final fetchApplicationProvider =
    FutureProvider.family<BusinessRegistrationDto, int>((
      ref,
      businessId,
    ) async {
      final api = ref.watch(businessOnboardingApiProvider);
      return api.getApplication(businessId);
    });

/// AsyncNotifier for submitting a registration update on a rejected business.
final updateRegistrationNotifierProvider =
    AsyncNotifierProvider<
      UpdateRegistrationNotifier,
      SubmitBusinessApplicationResponse?
    >(UpdateRegistrationNotifier.new);

class UpdateRegistrationNotifier
    extends AsyncNotifier<SubmitBusinessApplicationResponse?> {
  @override
  Future<SubmitBusinessApplicationResponse?> build() async => null;

  Future<void> submit({
    required int businessId,
    required BusinessRegistrationDto dto,
  }) async {
    state = const AsyncLoading();
    try {
      final api = ref.read(businessOnboardingApiProvider);
      final response = await api.updateBusinessRegistration(businessId, dto);

      // Update session state locally so router guard allows navigation
      ref
          .read(sessionControllerProvider.notifier)
          .updateBusinessStatus(
            businessId: businessId,
            newStatus: 'PENDING_VERIFICATION',
            rejectionReason: null,
          );

      state = AsyncData(response);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void reset() => state = const AsyncData(null);
}
