import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../data/earn_points_repository.dart';
import '../../data/models/resolved_guest.dart';
import '../../data/models/points_preview.dart';
import '../../data/models/earn_transaction_request.dart';

// ── Wizard step enum ────────────────────────────────────────────────────────

enum WizardStep { guestIdentification, billDetails, confirmation }

// ── Scanner sub-state ───────────────────────────────────────────────────────

enum ScannerStatus {
  /// Camera active, waiting for QR.
  scanning,

  /// QR detected, looking up customer on backend.
  lookingUp,

  /// Customer resolved successfully.
  resolved,

  /// QR payload invalid or customer not found.
  error,
}

// ── Draft state ─────────────────────────────────────────────────────────────

class EarnPointsDraftState {
  const EarnPointsDraftState({
    this.currentStep = WizardStep.guestIdentification,
    this.guests = const [],
    this.scannerStatus = ScannerStatus.scanning,
    this.scannerErrorMessage,
    this.billAmount,
    this.invoiceNumber,
    this.note,
    this.preview,
    this.isPreviewLoading = false,
    this.previewError,
    this.isSubmitting = false,
    this.submissionError,
    this.isSuccess = false,
    this.totalPointsAwarded,
    this.lastScannedRaw,
    this.finalResult,
    this.idempotencyKey,
  });

  final WizardStep currentStep;
  final List<ResolvedGuest> guests;
  final ScannerStatus scannerStatus;
  final String? scannerErrorMessage;
  final double? billAmount;
  final String? invoiceNumber;
  final String? note;
  final PointsPreview? preview;
  final bool isPreviewLoading;
  final String? previewError;
  final bool isSubmitting;
  final String? submissionError;
  final bool isSuccess;
  final int? totalPointsAwarded;
  final PointsPreview? finalResult;
  final String? idempotencyKey;

  /// Raw value of the last scanned QR — used to prevent duplicate reads.
  final String? lastScannedRaw;

  // ── Computed helpers ──

  bool get hasGuests => guests.isNotEmpty;
  bool get isMultiGuest => guests.length > 1;
  int get guestCount => guests.length;
  static const int maxGuests = 8;
  bool get canAddGuest => guests.length < maxGuests;

  /// Whether the bill details form is valid enough to proceed.
  bool get isBillValid =>
      billAmount != null && billAmount! > 0 && hasGuests;

  EarnPointsDraftState copyWith({
    WizardStep? currentStep,
    List<ResolvedGuest>? guests,
    ScannerStatus? scannerStatus,
    String? scannerErrorMessage,
    bool clearScannerError = false,
    double? billAmount,
    bool clearBillAmount = false,
    String? invoiceNumber,
    String? note,
    PointsPreview? preview,
    bool clearPreview = false,
    bool? isPreviewLoading,
    String? previewError,
    bool clearPreviewError = false,
    bool? isSubmitting,
    String? submissionError,
    bool clearSubmissionError = false,
    bool? isSuccess,
    int? totalPointsAwarded,
    String? lastScannedRaw,
    bool clearLastScanned = false,
    PointsPreview? finalResult,
    bool clearFinalResult = false,
    String? idempotencyKey,
    bool clearIdempotencyKey = false,
  }) {
    return EarnPointsDraftState(
      currentStep: currentStep ?? this.currentStep,
      guests: guests ?? this.guests,
      scannerStatus: scannerStatus ?? this.scannerStatus,
      scannerErrorMessage: clearScannerError
          ? null
          : (scannerErrorMessage ?? this.scannerErrorMessage),
      billAmount:
          clearBillAmount ? null : (billAmount ?? this.billAmount),
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      note: note ?? this.note,
      preview: clearPreview ? null : (preview ?? this.preview),
      isPreviewLoading: isPreviewLoading ?? this.isPreviewLoading,
      previewError:
          clearPreviewError ? null : (previewError ?? this.previewError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionError: clearSubmissionError
          ? null
          : (submissionError ?? this.submissionError),
      isSuccess: isSuccess ?? this.isSuccess,
      totalPointsAwarded: totalPointsAwarded ?? this.totalPointsAwarded,
      lastScannedRaw:
          clearLastScanned ? null : (lastScannedRaw ?? this.lastScannedRaw),
      finalResult:
          clearFinalResult ? null : (finalResult ?? this.finalResult),
      idempotencyKey: clearIdempotencyKey ? null : (idempotencyKey ?? this.idempotencyKey),
    );
  }
}

// ── Controller ──────────────────────────────────────────────────────────────

class EarnPointsController extends Notifier<EarnPointsDraftState> {
  @override
  EarnPointsDraftState build() => const EarnPointsDraftState();

  EarnPointsRepository get _repo =>
      ref.read(earnPointsRepositoryProvider);

  // ── Scanner Actions ───────────────────────────────────────────────────────

  /// Called when the scanner detects a QR code.
  /// Returns true if this is a new, accepted scan.
  bool onQrDetected(String rawValue) {
    // Deduplicate: ignore if same as last scan.
    if (rawValue == state.lastScannedRaw &&
        state.scannerStatus != ScannerStatus.error) {
      return false;
    }

    state = state.copyWith(
      scannerStatus: ScannerStatus.lookingUp,
      lastScannedRaw: rawValue,
      clearScannerError: true,
    );
    return true;
  }

  /// Perform backend lookup for a scanned qr token.
  Future<void> lookupGuest({
    required int businessId,
    required String qrToken,
  }) async {
    state = state.copyWith(
      scannerStatus: ScannerStatus.lookingUp,
      clearScannerError: true,
    );

    try {
      final guest = await _repo.lookupByQrToken(
        businessId: businessId,
        qrToken: qrToken,
      );

      // Check for duplicate guest already in the list.
      if (state.guests.any((g) => g.customerId == guest.customerId)) {
        state = state.copyWith(
          scannerStatus: ScannerStatus.error,
          scannerErrorMessage: '${guest.fullName} is already added',
        );
        return;
      }

      state = state.copyWith(
        scannerStatus: ScannerStatus.resolved,
        guests: [...state.guests, guest],
      );
    } catch (e) {
      final message = _extractErrorMessage(e);
      state = state.copyWith(
        scannerStatus: ScannerStatus.error,
        scannerErrorMessage: message,
      );
    }
  }

  /// Add a guest from manual search.
  void addGuestFromSearch(ResolvedGuest guest) {
    if (state.guests.any((g) => g.customerId == guest.customerId)) return;
    state = state.copyWith(
      guests: [...state.guests, guest],
      scannerStatus: ScannerStatus.resolved,
    );
  }

  /// Remove a guest by customer ID.
  void removeGuest(int customerId) {
    state = state.copyWith(
      guests: state.guests.where((g) => g.customerId != customerId).toList(),
      clearPreview: true,
      clearIdempotencyKey: true,
    );
    // If no guests remain, reset scanner.
    if (state.guests.isEmpty) {
      state = state.copyWith(scannerStatus: ScannerStatus.scanning);
    }
  }

  /// Reset scanner to accept a new QR code (for "Add another guest").
  void resumeScanning() {
    state = state.copyWith(
      scannerStatus: ScannerStatus.scanning,
      clearScannerError: true,
      clearLastScanned: true,
    );
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  void goToStep(WizardStep step) {
    state = state.copyWith(currentStep: step);
  }

  void confirmGuests() {
    if (!state.hasGuests) return;
    state = state.copyWith(currentStep: WizardStep.billDetails);
  }

  void goToConfirmation() {
    if (!state.isBillValid) return;
    state = state.copyWith(
      currentStep: WizardStep.confirmation,
      idempotencyKey: state.idempotencyKey ?? const Uuid().v4(),
    );
  }

  // ── Bill Details ──────────────────────────────────────────────────────────

  void updateBillAmount(double? amount) {
    state = state.copyWith(
      billAmount: amount,
      clearBillAmount: amount == null,
      clearPreview: true,
      clearPreviewError: true,
      clearIdempotencyKey: true,
    );
  }

  void updateInvoiceNumber(String value) {
    state = state.copyWith(
      invoiceNumber: value,
      clearIdempotencyKey: true,
    );
  }

  void updateNote(String value) {
    state = state.copyWith(
      note: value,
      clearIdempotencyKey: true,
    );
  }

  // ── Points Preview ────────────────────────────────────────────────────────

  Future<void> fetchPreview({required int businessId}) async {
    if (!state.isBillValid) return;

    state = state.copyWith(
      isPreviewLoading: true,
      clearPreviewError: true,
    );

    try {
      // Map to a list of Guest objects instead of a list of ints
      final guestsPayload = state.guests
          .map((g) => GuestAllocation(customerId: g.customerId))
          .toList();

      final preview = await _repo.previewPoints(
        businessId: businessId,
        billAmount: state.billAmount!,
        guests: guestsPayload, // Passed the objects here
      );

      state = state.copyWith(
        preview: preview,
        isPreviewLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isPreviewLoading: false,
        previewError: _extractErrorMessage(e),
      );
    }
  }


  // ── Submission ────────────────────────────────────────────────────────────

  Future<bool> submitTransaction({required int businessId}) async {
    if (!state.isBillValid) return false;

    state = state.copyWith(
      isSubmitting: true,
      clearSubmissionError: true,
    );

    try {
      final request = EarnTransactionRequest(
        billAmount: state.billAmount!,
        guests: List.generate(
          state.guestCount,
          (i) => GuestAllocation(
            customerId: state.guests[i].customerId,
          ),
        ),
        invoiceNumber: state.invoiceNumber,
        note: state.note,
      );

      final response = await _repo.submitEarnTransaction(
        businessId: businessId,
        request: request,
        idempotencyKey: state.idempotencyKey!,
      );

      state = state.copyWith(
        isSubmitting: false,
        isSuccess: true,
        finalResult: response,
        totalPointsAwarded: response.totalPoints,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        submissionError: _extractErrorMessage(e),
      );
      return false;
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────────

  void reset() {
    state = const EarnPointsDraftState();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _extractErrorMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] as String?) ??
            (data['error'] as String?) ??
            'Something went wrong';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Connection timed out. Please try again.';
      }
      return 'Network error. Check your connection.';
    }
    return error.toString();
  }
}


// ── Provider ────────────────────────────────────────────────────────────────

final earnPointsControllerProvider =
    NotifierProvider<EarnPointsController, EarnPointsDraftState>(
      EarnPointsController.new,
    );
