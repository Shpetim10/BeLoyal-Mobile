import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_controller.dart';

/// UI state for the Login screen.
class LoginUiState {
  const LoginUiState({
    this.user,
    this.errorMessage,
    this.errorCode,
    this.fieldErrors = const {},
  });

  final AuthUser? user;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, String> fieldErrors;

  bool get isSuccess => user != null;
  bool get hasError => errorMessage != null;
}

class LoginController extends AsyncNotifier<LoginUiState> {
  @override
  Future<LoginUiState> build() async => const LoginUiState();

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();

    final authController = ref.read(authControllerProvider);
    final result = await authController.login(email, password);

    state = switch (result) {
      AuthSuccess(data: final user) => AsyncData(LoginUiState(user: user)),
      AuthError(failure: final f) => AsyncData(
          LoginUiState(
            errorMessage: f.message,
            errorCode: f.errorCode,
            fieldErrors: f.fieldErrors ?? {},
          ),
        ),
    };
  }

  void clearError() {
    state = const AsyncData(LoginUiState());
  }
}

final loginControllerProvider =
    AsyncNotifierProvider<LoginController, LoginUiState>(LoginController.new);
