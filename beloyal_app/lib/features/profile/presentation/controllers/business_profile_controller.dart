import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/models/business_profile.dart';
import '../../data/repositories/business_profile_repository.dart';

class BusinessProfilePageState {
  const BusinessProfilePageState({
    this.business,
    this.isSaving = false,
    this.isUploadingLogo = false,
    this.errorMessage,
    this.fieldErrors = const {},
    this.pendingLogo,
  });

  final BusinessProfile? business;
  final bool isSaving;
  final bool isUploadingLogo;
  final String? errorMessage;
  final Map<String, String> fieldErrors;
  final XFile? pendingLogo;

  BusinessProfilePageState copyWith({
    BusinessProfile? business,
    bool? isSaving,
    bool? isUploadingLogo,
    String? errorMessage,
    Map<String, String>? fieldErrors,
    XFile? pendingLogo,
    bool clearError = false,
    bool clearPendingLogo = false,
  }) {
    return BusinessProfilePageState(
      business: business ?? this.business,
      isSaving: isSaving ?? this.isSaving,
      isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      pendingLogo: clearPendingLogo ? null : (pendingLogo ?? this.pendingLogo),
    );
  }
}

class BusinessProfileController
    extends AsyncNotifier<BusinessProfilePageState> {
  @override
  Future<BusinessProfilePageState> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const BusinessProfilePageState();
    return _fetch();
  }

  Future<BusinessProfilePageState> _fetch() async {
    final session = ref.read(sessionControllerProvider);
    if (session == null) {
      return const BusinessProfilePageState(errorMessage: 'Not authenticated');
    }

    final repo = ref.read(businessProfileRepositoryProvider);
    final businessId = session.activeBusinessId;
    if (businessId == null) {
      return const BusinessProfilePageState(
        errorMessage: 'No active business associated with this account',
      );
    }
    final result = await repo.fetchMyBusiness(businessId);

    if (result is AuthSuccess<BusinessProfile>) {
      return BusinessProfilePageState(business: result.data);
    } else if (result is AuthError<BusinessProfile>) {
      return BusinessProfilePageState(errorMessage: result.failure.message);
    }

    return const BusinessProfilePageState(
      errorMessage: 'Failed to load business profile',
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch());
  }

  void clearMessages() {
    if (state.value != null) {
      state = AsyncData(state.value!.copyWith(clearError: true));
    }
  }

  /// Update editable business fields (RESTAURANT_ADMIN).
  Future<void> updateBusiness({
    String? businessName,
    String? businessType,
    String? publicDescription,
    String? address,
    String? city,
    String? country,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
  }) async {
    if (state.value == null) return;

    state = AsyncData(state.value!.copyWith(isSaving: true, clearError: true));

    final session = ref.read(sessionControllerProvider);
    final businessId = session?.activeBusinessId;
    if (businessId == null) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: 'Business context missing',
        ),
      );
      return;
    }

    final repo = ref.read(businessProfileRepositoryProvider);
    final result = await repo.updateMyBusiness(
      businessId: businessId,
      businessName: businessName,
      businessType: businessType,
      publicDescription: publicDescription,
      address: address,
      city: city,
      country: country,
      websiteUrl: websiteUrl,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
    );

    if (result is AuthSuccess<BusinessProfile>) {
      state = AsyncData(
        state.value!.copyWith(isSaving: false, business: result.data),
      );
    } else if (result is AuthError<BusinessProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: result.failure.message,
          fieldErrors: result.failure.fieldErrors ?? const {},
        ),
      );
    }
  }

  Future<void> uploadLogo(XFile file) async {
    if (state.value == null || state.value!.business == null) return;

    final businessId = state.value!.business!.id;

    state = AsyncData(
      state.value!.copyWith(
        isUploadingLogo: true,
        clearError: true,
        pendingLogo: file,
      ),
    );

    try {
      final repo = ref.read(businessProfileRepositoryProvider);
      final upload = await repo.uploadLogo(
        file: file,
        businessId: businessId,
        ref: ref,
      );

      final url = upload['url'];
      final key = upload['key'];
      if (url == null || key == null) {
        throw Exception('Failed to retrieve logo URL or key');
      }

      final updateResult = await repo.updateMyBusiness(
        businessId: businessId,
        logoPath: url,
        logoKey: key,
      );

      if (updateResult is AuthSuccess<BusinessProfile>) {
        state = AsyncData(
          state.value!.copyWith(
            isUploadingLogo: false,
            business: updateResult.data,
            clearPendingLogo: true,
          ),
        );
      } else if (updateResult is AuthError<BusinessProfile>) {
        state = AsyncData(
          state.value!.copyWith(
            isUploadingLogo: false,
            errorMessage: updateResult.failure.message,
            clearPendingLogo: true,
          ),
        );
      }
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          isUploadingLogo: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearPendingLogo: true,
        ),
      );
    }
  }

  Future<void> removeLogo() async {
    if (state.value == null || state.value!.business == null) return;

    state = AsyncData(state.value!.copyWith(isSaving: true, clearError: true));

    try {
      final session = ref.read(sessionControllerProvider);
      final businessId = session?.activeBusinessId;
      if (businessId == null) {
        state = AsyncData(
          state.value!.copyWith(
            isSaving: false,
            errorMessage: 'Business context missing',
          ),
        );
        return;
      }

      final repo = ref.read(businessProfileRepositoryProvider);
      // Send null/empty to clear logo on backend
      await repo.updateMyBusiness(
        businessId: businessId,
        logoPath: '',
        logoKey: '',
      );
      // Re-fetch to get updated data
      final result = await repo.fetchMyBusiness(businessId);
      if (result is AuthSuccess<BusinessProfile>) {
        state = AsyncData(
          state.value!.copyWith(isSaving: false, business: result.data),
        );
      } else {
        state = AsyncData(state.value!.copyWith(isSaving: false));
      }
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}

final businessProfileControllerProvider =
    AsyncNotifierProvider<BusinessProfileController, BusinessProfilePageState>(
      BusinessProfileController.new,
    );
