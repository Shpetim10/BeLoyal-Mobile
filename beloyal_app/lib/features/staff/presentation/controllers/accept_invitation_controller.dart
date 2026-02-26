import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/staff_invitation_repository.dart';

/// UI state for the Accept Staff Invitation screen.
class AcceptInvitationUiState {
  const AcceptInvitationUiState({
    this.successMessage,
    this.errorMessage,
    this.errorCode,
    this.fieldErrors = const {},
    this.isNewUser = false,
  });

  final String? successMessage;
  final String? errorMessage;
  final String? errorCode;
  final Map<String, String> fieldErrors;
  final bool isNewUser;

  bool get isSuccess => successMessage != null;
  bool get hasError => errorMessage != null;
}

/// Controller managing state for the Accept Staff Invitation page.
class AcceptInvitationController
    extends AsyncNotifier<AcceptInvitationUiState> {
  @override
  Future<AcceptInvitationUiState> build() async =>
      const AcceptInvitationUiState();

  Future<void> submitRegistration({
    required String token,
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    String? phoneNumber,
    required String password,
    required bool acceptedTc,
  }) async {
    state = const AsyncLoading();

    final repo = ref.read(staffInvitationRepositoryProvider);
    final result = await repo.registerNewStaffMember(
      token: token,
      firstName: firstName,
      lastName: lastName,
      email: email,
      username: username,
      phoneNumber: phoneNumber,
      password: password,
      acceptedTc: acceptedTc,
      acceptedTcVersion: 'v1.0',
    );

    state = switch (result) {
      AuthSuccess(data: final msg) => AsyncData(
        AcceptInvitationUiState(successMessage: msg, isNewUser: true),
      ),
      AuthError(failure: final f) => AsyncData(
        AcceptInvitationUiState(
          errorMessage: f.message,
          errorCode: f.errorCode,
          fieldErrors: f.fieldErrors ?? {},
        ),
      ),
    };

    // Note: Do not auto-login and set role for new user registration,
    // as the user needs to verify their email address first.
  }

  Future<void> acceptAsExistingUser({required String token}) async {
    state = const AsyncLoading();

    final repo = ref.read(staffInvitationRepositoryProvider);
    final result = await repo.acceptInvitationAsExistingUser(token: token);

    state = switch (result) {
      AuthSuccess(data: final msg) => AsyncData(
        AcceptInvitationUiState(successMessage: msg),
      ),
      AuthError(failure: final f) => AsyncData(
        AcceptInvitationUiState(
          errorMessage: f.message,
          errorCode: f.errorCode,
          fieldErrors: f.fieldErrors ?? {},
        ),
      ),
    };

    if (result is AuthSuccess) {
      await _refreshAndSetStaffRole();
    }
  }

  Future<void> _refreshAndSetStaffRole() async {
    // 1. Silently fetch the updated user profile from the backend
    await ref.read(authControllerProvider).tryAutoLogin();

    // 2. Switch the active role to STAFF or BUSINESS_ADMIN so the dashboard loads correctly
    final session = ref.read(sessionControllerProvider);
    if (session != null) {
      // Prefer staff profile if possible since they just accepted a staff invitation
      final staffProfiles = session.user.businessProfiles
          .where((p) => p.role == UserRole.staff)
          .toList();

      final businessAdminProfiles = session.user.businessProfiles
          .where((p) => p.role == UserRole.businessAdmin)
          .toList();

      final staffProfile = staffProfiles.isNotEmpty
          ? staffProfiles.last
          : businessAdminProfiles.lastOrNull;

      if (staffProfile != null) {
        ref
            .read(sessionControllerProvider.notifier)
            .switchRole(
              staffProfile.role,
              businessId: staffProfile.businessId,
              businessName: staffProfile.businessName,
            );
      }
    }
  }

  void clearError() {
    state = const AsyncData(AcceptInvitationUiState());
  }
}

final acceptInvitationControllerProvider =
    AsyncNotifierProvider<AcceptInvitationController, AcceptInvitationUiState>(
      AcceptInvitationController.new,
    );
