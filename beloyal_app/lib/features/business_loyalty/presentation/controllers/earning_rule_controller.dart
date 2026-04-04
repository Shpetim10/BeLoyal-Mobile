import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/earning_rule_repository.dart';

class EarningRuleState {
  const EarningRuleState({
    this.pointsPer = 1,
    this.amountPer = 100.0,
    this.isDirty = false,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final int pointsPer;
  final double amountPer;
  final bool isDirty;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  bool get isValid => amountPer > 0 && pointsPer >= 0;

  EarningRuleState copyWith({
    int? pointsPer,
    double? amountPer,
    bool? isDirty,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EarningRuleState(
      pointsPer: pointsPer ?? this.pointsPer,
      amountPer: amountPer ?? this.amountPer,
      isDirty: isDirty ?? this.isDirty,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class EarningRuleController extends Notifier<EarningRuleState> {
  @override
  EarningRuleState build() {
    return const EarningRuleState();
  }

  void updateFields({int? pointsPer, double? amountPer}) {
    state = state.copyWith(
      pointsPer: pointsPer,
      amountPer: amountPer,
      isDirty: true,
      clearError: true,
    );
  }

  void applyPreset({required int pointsPer, required double amountPer}) {
    state = state.copyWith(
      pointsPer: pointsPer,
      amountPer: amountPer,
      isDirty: true,
      clearError: true,
    );
  }

  Future<void> fetch(int businessId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(earningRuleRepositoryProvider);
      final data = await repo.getEarningSettings(businessId: businessId);
      
      final pointsPer = data['pointsPer'] as int? ?? 1;
      final amountRaw = data['amountPer'];
      final amountPer = amountRaw == null ? 100.0 : (amountRaw as num).toDouble();

      state = state.copyWith(
        pointsPer: pointsPer,
        amountPer: amountPer,
        isLoading: false,
        isDirty: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch earning rules, using defaults.',
      );
    }
  }

  Future<bool> save(int businessId) async {
    if (!state.isValid) return false;

    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final repo = ref.read(earningRuleRepositoryProvider);
      await repo.patchEarningSettings(
        businessId: businessId,
        amountPer: state.amountPer,
        pointsPer: state.pointsPer,
      );

      state = state.copyWith(isSaving: false, isDirty: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save earning rule: $e',
      );
      return false;
    }
  }
}

final earningRuleControllerProvider =
    NotifierProvider<EarningRuleController, EarningRuleState>(
      EarningRuleController.new,
    );
