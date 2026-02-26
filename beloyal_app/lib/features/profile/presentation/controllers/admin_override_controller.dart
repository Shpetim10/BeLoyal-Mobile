import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/business_profile.dart';
import '../../data/business_profile_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

// ─────────────────────────── State ───────────────────────────────────────────

class AdminOverrideState {
  const AdminOverrideState({
    this.business,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors = const {},
  });

  final BusinessProfile? business;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String> fieldErrors;

  AdminOverrideState copyWith({
    BusinessProfile? business,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AdminOverrideState(
      business: business ?? this.business,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess
          ? null
          : (successMessage ?? this.successMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

// ─────────────────────────── Controller ──────────────────────────────────────

/// Controller used by Super Admin to override/edit all business fields
/// from the ApplicationDetailsPage (business details view in admin dashboard).
class AdminOverrideController extends AsyncNotifier<AdminOverrideState> {
  @override
  Future<AdminOverrideState> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const AdminOverrideState();
    return const AdminOverrideState();
  }

  /// Load a business's current profile for editing.
  Future<void> loadBusiness(int businessId) async {
    state = const AsyncLoading();
    final repo = ref.read(businessProfileRepositoryProvider);
    final result = await repo.fetchBusiness(businessId);

    if (result is AuthSuccess<BusinessProfile>) {
      state = AsyncData(AdminOverrideState(business: result.data));
    } else if (result is AuthError<BusinessProfile>) {
      state = AsyncData(
        AdminOverrideState(errorMessage: result.failure.message),
      );
    }
  }

  /// Save all fields including restricted ones (vatId, status, etc.)
  /// via PATCH /admin/business/{businessId}.
  Future<bool> updateAllFields({
    required int businessId,
    String? businessName,
    String? businessType,
    String? publicDescription,
    String? address,
    String? city,
    String? country,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
    String? vatId,
    String? status,
    String? logoPath,
    String? logoKey,
  }) async {
    if (state.value == null) return false;

    state = AsyncData(
      state.value!.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(businessProfileRepositoryProvider);
    final result = await repo.adminUpdateBusiness(
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
      vatId: vatId,
      status: status,
      logoPath: logoPath,
      logoKey: logoKey,
    );

    if (result is AuthSuccess<BusinessProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          business: result.data,
          successMessage: 'Business details updated successfully',
        ),
      );
      return true;
    } else if (result is AuthError<BusinessProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: result.failure.message,
          fieldErrors: result.failure.fieldErrors ?? const {},
        ),
      );
      return false;
    }

    return false;
  }

  void clearMessages() {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(clearError: true, clearSuccess: true),
      );
    }
  }
}

final adminOverrideControllerProvider =
    AsyncNotifierProvider<AdminOverrideController, AdminOverrideState>(
      AdminOverrideController.new,
    );
