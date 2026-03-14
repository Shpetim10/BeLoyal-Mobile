import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../media/data/repositories/media_repository.dart';
import '../../domain/models/staff_membership.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';

class StaffProfilePageState {
  const StaffProfilePageState({
    this.user,
    this.membership,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.saveSuccessMessage,
    this.fieldErrors,
    this.pendingAvatar,
  });

  final UserProfile? user;
  final StaffMembership? membership;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? saveSuccessMessage;
  final Map<String, String>? fieldErrors;
  final XFile? pendingAvatar;

  StaffProfilePageState copyWith({
    UserProfile? user,
    StaffMembership? membership,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? saveSuccessMessage,
    Map<String, String>? fieldErrors,
    XFile? pendingAvatar,
    bool clearPendingAvatar = false,
    bool clearError = false,
    bool clearSuccess = false,
    bool clearFieldErrors = false,
  }) {
    return StaffProfilePageState(
      user: user ?? this.user,
      membership: membership ?? this.membership,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      saveSuccessMessage: clearSuccess
          ? null
          : (saveSuccessMessage ?? this.saveSuccessMessage),
      fieldErrors: clearFieldErrors ? null : (fieldErrors ?? this.fieldErrors),
      pendingAvatar: clearPendingAvatar
          ? null
          : (pendingAvatar ?? this.pendingAvatar),
    );
  }
}

class StaffProfileController extends AsyncNotifier<StaffProfilePageState> {
  @override
  Future<StaffProfilePageState> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const StaffProfilePageState();
    return _fetch();
  }

  Future<StaffProfilePageState> _fetch() async {
    final session = ref.read(sessionControllerProvider);
    if (session == null) return const StaffProfilePageState();

    state = const AsyncValue.loading();

    final currentStore = state.hasValue
        ? state.value!
        : const StaffProfilePageState();
    state = AsyncValue.data(currentStore.copyWith(isLoading: true));

    final repo = ref.read(profileRepositoryProvider);

    // Fetch user profile
    final userRes = await repo.fetchUserProfile();
    UserProfile? updatedUser;
    StaffMembership? updatedMembership;
    String? error;

    if (userRes is AuthSuccess<UserProfile>) {
      updatedUser = userRes.data;
    } else if (userRes is AuthError<UserProfile>) {
      error = userRes.failure.message;
    }

    // Fetch staff membership (if active business is set in session)
    final businessId = session.activeBusinessId;
    if (businessId != null) {
      final memRes = await repo.fetchStaffMembership(businessId);
      if (memRes is AuthSuccess<StaffMembership>) {
        updatedMembership = memRes.data;
      } else if (memRes is AuthError<StaffMembership>) {
        // Only set error if we don't already have one from the user fetch
        error ??= memRes.failure.message;
      }
    } else {
      error ??= 'No active business selected.';
    }

    final newState = currentStore.copyWith(
      user: updatedUser,
      membership: updatedMembership,
      isLoading: false,
      errorMessage: error,
      clearError: error == null,
    );

    state = AsyncValue.data(newState);
    return newState;
  }

  Future<void> refresh() async {
    await _fetch();
  }

  void clearMessages() {
    state = AsyncValue.data(
      state.requireValue.copyWith(
        clearError: true,
        clearSuccess: true,
        clearFieldErrors: true,
      ),
    );
  }

  Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? phoneNumber,
    bool clearPhoneNumber = false,
  }) async {
    final currentState = state.requireValue;
    state = AsyncValue.data(
      currentState.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(profileRepositoryProvider);
    final res = await repo.updateUserProfile(
      firstName: firstName,
      lastName: lastName,
      username: username,
      phoneNumber: phoneNumber,
      clearPhoneNumber: clearPhoneNumber,
    );

    if (res is AuthSuccess<UserProfile>) {
      state = AsyncValue.data(
        currentState.copyWith(
          user: res.data,
          isSaving: false,
          saveSuccessMessage: 'Profile updated successfully',
        ),
      );
    } else if (res is AuthError<UserProfile>) {
      state = AsyncValue.data(
        currentState.copyWith(
          isSaving: false,
          errorMessage: res.failure.message,
          fieldErrors: res.failure.fieldErrors,
        ),
      );
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    final currentState = state.requireValue;
    state = AsyncValue.data(
      currentState.copyWith(
        pendingAvatar: file,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final mediaRepo = ref.read(mediaRepositoryProvider);
    final profileRepo = ref.read(profileRepositoryProvider);

    try {
      final uploadRes = await mediaRepo.uploadImage(
        file: file,
        category: 'USER_PROFILE',
        ownerId: currentState.user?.userId ?? 0,
      );

      final imgPath = uploadRes['imageUrl'] ?? uploadRes['imagePath'];
      final imgKey = uploadRes['imageKey'];

      if (imgPath == null || imgKey == null) {
        throw Exception('Failed to get mapped image path/key');
      }

      final updateRes = await profileRepo.updateUserProfile(
        profileImageUrl: imgPath,
        profileImageKey: imgKey,
      );

      if (updateRes is AuthSuccess<UserProfile>) {
        state = AsyncValue.data(
          currentState.copyWith(
            user: updateRes.data,
            saveSuccessMessage: 'Avatar updated successfully',
            clearPendingAvatar: true,
          ),
        );
      } else if (updateRes is AuthError<UserProfile>) {
        state = AsyncValue.data(
          currentState.copyWith(
            errorMessage: updateRes.failure.message,
            clearPendingAvatar: true,
          ),
        );
      }
    } catch (e) {
      state = AsyncValue.data(
        currentState.copyWith(
          errorMessage: 'Failed to upload image: $e',
          clearPendingAvatar: true,
        ),
      );
    }
  }

  Future<void> removeAvatar() async {
    final currentState = state.requireValue;
    state = AsyncValue.data(
      currentState.copyWith(
        isSaving: true,
        clearError: true,
        clearSuccess: true,
      ),
    );

    final repo = ref.read(profileRepositoryProvider);
    final res = await repo.updateUserProfile(clearProfileImageUrl: true);

    if (res is AuthSuccess<UserProfile>) {
      state = AsyncValue.data(
        currentState.copyWith(
          user: res.data,
          isSaving: false,
          saveSuccessMessage: 'Avatar removed successfully',
        ),
      );
    } else if (res is AuthError<UserProfile>) {
      state = AsyncValue.data(
        currentState.copyWith(
          isSaving: false,
          errorMessage: res.failure.message,
        ),
      );
    }
  }
}

final staffProfileControllerProvider =
    AsyncNotifierProvider<StaffProfileController, StaffProfilePageState>(
      StaffProfileController.new,
    );
