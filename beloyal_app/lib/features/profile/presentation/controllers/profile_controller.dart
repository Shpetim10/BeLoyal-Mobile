import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../media/data/repositories/media_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/customer_profile.dart';
import '../../data/repositories/profile_repository.dart';

class ProfilePageState {
  const ProfilePageState({
    this.user,
    this.customer,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveSuccessMessage,
    this.fieldErrors = const {},
    this.pendingAvatar,
  });

  final UserProfile? user;
  final CustomerProfile? customer;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveSuccessMessage;
  final Map<String, String> fieldErrors;
  final XFile? pendingAvatar;

  ProfilePageState copyWith({
    UserProfile? user,
    CustomerProfile? customer,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveSuccessMessage,
    Map<String, String>? fieldErrors,
    XFile? pendingAvatar,
    bool clearPendingAvatar = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ProfilePageState(
      user: user ?? this.user,
      customer: customer ?? this.customer,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveSuccessMessage: clearSuccess
          ? null
          : (saveSuccessMessage ?? this.saveSuccessMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
      pendingAvatar: clearPendingAvatar
          ? null
          : (pendingAvatar ?? this.pendingAvatar),
    );
  }
}

class ProfileController extends AsyncNotifier<ProfilePageState> {
  @override
  Future<ProfilePageState> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const ProfilePageState();
    return _fetchProfiles();
  }

  Future<ProfilePageState> _fetchProfiles() async {
    final repo = ref.read(profileRepositoryProvider);
    final session = ref.read(sessionControllerProvider);

    if (session == null) {
      return const ProfilePageState(errorMessage: 'Not authenticated');
    }

    final userResult = await repo.fetchUserProfile();
    UserProfile? user;
    String? error;

    if (userResult is AuthSuccess<UserProfile>) {
      user = userResult.data;
    } else if (userResult is AuthError<UserProfile>) {
      error = userResult.failure.message;
    }

    CustomerProfile? customer;

    // Fetch customer profile unconditionally or if they have the role.
    // Usually even non-customers might have an empty profile or return 404, we handle that in repo.
    if (session.user.roles.contains(UserRole.customer) ||
        session.user.customerProfileComplete) {
      final customerResult = await repo.fetchCustomerProfile();
      if (customerResult is AuthSuccess<CustomerProfile>) {
        customer = customerResult.data;
      } else if (customerResult is AuthError<CustomerProfile> &&
          error == null) {
        // Only override error if we don't already have one from user profile fetch
        error = customerResult.failure.message;
      }
    }

    return ProfilePageState(
      user: user,
      customer: customer,
      errorMessage: error,
    );
  }

  Future<void> refreshProfile() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchProfiles());
  }

  void clearMessages() {
    if (state.value != null) {
      state = AsyncData(
        state.value!.copyWith(clearError: true, clearSuccess: true),
      );
    }
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    bool clearPhoneNumber = false,
  }) async {
    if (state.value == null) return;

    state = AsyncData(
      state.value!.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      phoneNumber: phoneNumber,
      clearPhoneNumber: clearPhoneNumber,
    );

    if (result is AuthSuccess<UserProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          user: result.data,
          saveSuccessMessage: 'Profile updated successfully',
        ),
      );
    } else if (result is AuthError<UserProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: result.failure.message,
          fieldErrors: result.failure.fieldErrors ?? const {},
        ),
      );
    }
  }

  Future<void> updateCustomerProfile({
    String? city,
    String? country,
    String? gender,
    DateTime? birthdate,
    bool clearCity = false,
    bool clearCountry = false,
    bool clearGender = false,
    bool clearBirthdate = false,
  }) async {
    if (state.value == null) return;

    state = AsyncData(
      state.value!.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateCustomerProfile(
      city: city,
      country: country,
      gender: gender,
      birthdate: birthdate,
      clearCity: clearCity,
      clearCountry: clearCountry,
      clearGender: clearGender,
      clearBirthdate: clearBirthdate,
    );

    if (result is AuthSuccess<CustomerProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          customer: result.data,
          saveSuccessMessage: 'Customer details updated',
        ),
      );
    } else if (result is AuthError<CustomerProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: result.failure.message,
          fieldErrors: result.failure.fieldErrors ?? const {},
        ),
      );
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    if (state.value == null || state.value!.user == null) return;

    state = AsyncData(
      state.value!.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
        pendingAvatar: file,
      ),
    );

    try {
      final session = ref.read(sessionControllerProvider);
      if (session == null) throw Exception('Not authenticated');

      final mediaRepo = ref.read(mediaRepositoryProvider);
      final uploadResult = await mediaRepo.uploadImage(
        file: file,
        category: 'USER_PROFILE',
        ownerId: session.user.userId,
      );

      final url = uploadResult['url'];
      final key = uploadResult['key'];
      if (url == null || key == null) {
        throw Exception('Failed to retrieve image URL or key');
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      final updateResult = await profileRepo.updateUserProfile(
        profileImageUrl: url,
        profileImageKey: key,
      );

      if (updateResult is AuthSuccess<UserProfile>) {
        state = AsyncData(
          state.value!.copyWith(
            isSaving: false,
            user: updateResult.data,
            saveSuccessMessage: 'Profile photo updated',
            clearPendingAvatar: true,
          ),
        );
      } else if (updateResult is AuthError<UserProfile>) {
        state = AsyncData(
          state.value!.copyWith(
            isSaving: false,
            errorMessage: updateResult.failure.message,
            clearPendingAvatar: true,
          ),
        );
      }
    } catch (e) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          clearPendingAvatar: true,
        ),
      );
    }
  }

  Future<void> removeAvatar() async {
    if (state.value == null || state.value!.user == null) return;

    state = AsyncData(
      state.value!.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.updateUserProfile(clearProfileImageUrl: true);

    if (result is AuthSuccess<UserProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          user: result.data,
          saveSuccessMessage: 'Profile photo removed',
        ),
      );
    } else if (result is AuthError<UserProfile>) {
      state = AsyncData(
        state.value!.copyWith(
          isSaving: false,
          errorMessage: result.failure.message,
        ),
      );
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, ProfilePageState>(
      ProfileController.new,
    );
