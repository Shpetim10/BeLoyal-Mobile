import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../data/profile_repository.dart';

class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.fieldErrors = const {},
  });

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, String> fieldErrors;

  bool get isSuccess => successMessage != null;

  ChangePasswordState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordState();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(profileRepositoryProvider);
    final result = await repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (result is AuthSuccess<String>) {
      state = state.copyWith(isLoading: false, successMessage: result.data);
    } else if (result is AuthError<String>) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failure.message,
        fieldErrors: result.failure.fieldErrors ?? const {},
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, successMessage: null);
  }
}

final changePasswordControllerProvider =
    NotifierProvider<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
