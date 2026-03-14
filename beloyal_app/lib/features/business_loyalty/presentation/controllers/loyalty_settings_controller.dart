import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/loyalty_settings_dto.dart';
import '../../data/repositories/loyalty_settings_repository.dart';

class LoyaltySettingsState {
  const LoyaltySettingsState({
    this.minPointsToRedeem = 100,
    this.maxPointsToRedeem = 5000,
    this.pointsPerUnitDiscount = 1,
    this.maxPointsPerTransaction = 5000,
    this.expiryType = ExpiryType.noExpiry,
    this.monthsToExpire = 12,
    this.isDirty = false,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final int minPointsToRedeem;
  final int maxPointsToRedeem;
  final int pointsPerUnitDiscount;
  final int maxPointsPerTransaction;
  final ExpiryType expiryType;
  final int monthsToExpire;
  final bool isDirty;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  /// Returns true when all required fields pass validation.
  bool get isValid {
    if (minPointsToRedeem < 1) return false;
    if (maxPointsToRedeem < 1) return false;
    if (maxPointsToRedeem < minPointsToRedeem) return false;
    if (pointsPerUnitDiscount < 1) return false;
    if (maxPointsPerTransaction < 0) return false;
    if (expiryType == ExpiryType.expireAfterXMonths && monthsToExpire < 1) {
      return false;
    }
    return true;
  }

  LoyaltySettingsState copyWith({
    int? minPointsToRedeem,
    int? maxPointsToRedeem,
    int? pointsPerUnitDiscount,
    int? maxPointsPerTransaction,
    ExpiryType? expiryType,
    int? monthsToExpire,
    bool? isDirty,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LoyaltySettingsState(
      minPointsToRedeem: minPointsToRedeem ?? this.minPointsToRedeem,
      maxPointsToRedeem: maxPointsToRedeem ?? this.maxPointsToRedeem,
      pointsPerUnitDiscount:
          pointsPerUnitDiscount ?? this.pointsPerUnitDiscount,
      maxPointsPerTransaction:
          maxPointsPerTransaction ?? this.maxPointsPerTransaction,
      expiryType: expiryType ?? this.expiryType,
      monthsToExpire: monthsToExpire ?? this.monthsToExpire,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  /// Preview: how many ALL discount for N points
  int discountFor(int points) {
    if (pointsPerUnitDiscount <= 0) return 0;
    return points ~/ pointsPerUnitDiscount;
  }

  LoyaltySettingsDto toDto() => LoyaltySettingsDto(
    minPointsToRedeem: minPointsToRedeem,
    maxPointsToRedeem: maxPointsToRedeem,
    pointsPerUnitDiscount: pointsPerUnitDiscount,
    maxPointsPerTransaction: maxPointsPerTransaction,
    expiryType: expiryType,
    monthsToExpire: expiryType == ExpiryType.expireAfterXMonths
        ? monthsToExpire
        : null,
  );
}

class LoyaltySettingsController extends Notifier<LoyaltySettingsState> {
  @override
  LoyaltySettingsState build() => const LoyaltySettingsState();

  /// Load current settings from backend (for management page).
  Future<void> load(int businessId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(loyaltySettingsRepositoryProvider);
      final dto = await repo.fetchLoyaltySettings(businessId: businessId);
      state = LoyaltySettingsState(
        minPointsToRedeem: dto.minPointsToRedeem,
        maxPointsToRedeem: dto.maxPointsToRedeem,
        pointsPerUnitDiscount: dto.pointsPerUnitDiscount,
        maxPointsPerTransaction: dto.maxPointsPerTransaction,
        expiryType: dto.expiryType,
        monthsToExpire: dto.monthsToExpire ?? 12,
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load settings: $e',
      );
    }
  }

  void updateFields({
    int? minPointsToRedeem,
    int? maxPointsToRedeem,
    int? pointsPerUnitDiscount,
    int? maxPointsPerTransaction,
    ExpiryType? expiryType,
    int? monthsToExpire,
  }) {
    state = state.copyWith(
      minPointsToRedeem: minPointsToRedeem,
      maxPointsToRedeem: maxPointsToRedeem,
      pointsPerUnitDiscount: pointsPerUnitDiscount,
      maxPointsPerTransaction: maxPointsPerTransaction,
      expiryType: expiryType,
      monthsToExpire: monthsToExpire,
      isDirty: true,
      clearError: true,
    );
  }

  void applyDefaultPreset() {
    state = LoyaltySettingsState(
      minPointsToRedeem: 100,
      maxPointsToRedeem: 5000,
      pointsPerUnitDiscount: 1,
      maxPointsPerTransaction: 5000,
      expiryType: ExpiryType.noExpiry,
      monthsToExpire: 12,
      isDirty: true,
    );
  }

  Future<bool> save(int businessId) async {
    if (!state.isValid) return false;
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final repo = ref.read(loyaltySettingsRepositoryProvider);
      await repo.patchLoyaltySettings(
        businessId: businessId,
        dto: state.toDto(),
      );
      state = state.copyWith(isSaving: false, isDirty: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save loyalty settings: $e',
      );
      return false;
    }
  }
}

final loyaltySettingsControllerProvider =
    NotifierProvider<LoyaltySettingsController, LoyaltySettingsState>(
      LoyaltySettingsController.new,
    );
