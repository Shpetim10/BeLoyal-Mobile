import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

class PasswordResetState {
  const PasswordResetState({
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

  PasswordResetState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, String>? fieldErrors,
    bool clearError = false,
  }) {
    return PasswordResetState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: successMessage ?? this.successMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }
}

class PasswordResetController extends Notifier<PasswordResetState> {
  @override
  PasswordResetState build() {
    return const PasswordResetState();
  }

  Future<void> forgetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.forgetPassword(email: email);

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

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.resetPassword(
      token: token,
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

final passwordResetControllerProvider =
    NotifierProvider<PasswordResetController, PasswordResetState>(
      PasswordResetController.new,
    );
