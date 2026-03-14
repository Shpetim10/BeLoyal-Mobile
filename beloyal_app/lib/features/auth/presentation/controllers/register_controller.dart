import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// UI state for the Registration screen.
class RegisterUiState {
  const RegisterUiState({
    this.successMessage,
    this.errorMessage,
    this.errorCode,
    this.fieldErrors = const {},
    this.registeredEmail,
  });

  final String? successMessage;
  final String? errorMessage;
  final String? errorCode; // NEW: for specific error handling
  final Map<String, String> fieldErrors;
  final String? registeredEmail;

  bool get isSuccess => successMessage != null;
  bool get hasError => errorMessage != null;
}

class RegisterController extends AsyncNotifier<RegisterUiState> {
  @override
  Future<RegisterUiState> build() async => const RegisterUiState();

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String username,
    String? phoneNumber,
    required bool acceptedTc,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.register(
      firstName: firstName.trim(),
      lastName: lastName.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      username: username.trim(),
      phoneNumber: phoneNumber,
      acceptedTc: acceptedTc,
      acceptedTcVersion: 'v1.0',
    );

    state = switch (result) {
      AuthSuccess(data: final msg) => AsyncData(
        RegisterUiState(
          successMessage: msg,
          registeredEmail: email.trim().toLowerCase(),
        ),
      ),
      AuthError(failure: final f) => AsyncData(
        RegisterUiState(
          errorMessage: f.message,
          errorCode: f.errorCode,
          fieldErrors: f.fieldErrors ?? {},
        ),
      ),
    };
  }

  void clearError() {
    state = const AsyncData(RegisterUiState());
  }
}

final registerControllerProvider =
AsyncNotifierProvider<RegisterController, RegisterUiState>(
  RegisterController.new,
);