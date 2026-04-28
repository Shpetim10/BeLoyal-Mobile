import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../data/catalog_item_repository.dart';
import '../../data/models/catalog_item_variant_summary_response.dart';
import '../../data/models/catalog_item_variant_update_request.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class CatalogItemVariantListState {
  const CatalogItemVariantListState({
    this.variants = const [],
    this.isLoading = false,
    this.error,
    this.isSubmitting = false,
  });

  final List<CatalogItemVariantSummaryResponse> variants;
  final bool isLoading;
  final String? error;
  final bool isSubmitting;

  CatalogItemVariantListState copyWith({
    List<CatalogItemVariantSummaryResponse>? variants,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isSubmitting,
  }) {
    return CatalogItemVariantListState(
      variants: variants ?? this.variants,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class VariantArg {
  final int businessId;
  final int itemId;
  const VariantArg({required this.businessId, required this.itemId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantArg &&
          runtimeType == other.runtimeType &&
          businessId == other.businessId &&
          itemId == other.itemId;

  @override
  int get hashCode => businessId.hashCode ^ itemId.hashCode;
}

class CatalogItemVariantController
    extends StateNotifier<CatalogItemVariantListState> {
  CatalogItemVariantController(this._ref, this._arg)
    : super(const CatalogItemVariantListState());

  final Ref _ref;
  final VariantArg _arg;

  CatalogItemRepository get _repo => _ref.read(catalogItemRepositoryProvider);

  Future<void> fetchVariants() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getVariants(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
      );
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(variants: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  Future<void> createVariant(CatalogItemVariantUpdateRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.createVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        request: request,
      );
      state = state.copyWith(isSubmitting: false);
      fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      rethrow;
    }
  }

  Future<void> updateVariant(int variantId, CatalogItemVariantUpdateRequest request) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.updateVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        variantId: variantId,
        request: request,
      );
      state = state.copyWith(isSubmitting: false);
      fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      rethrow;
    }
  }

  Future<void> activateVariant(int variantId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.activateVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        variantId: variantId,
      );
      await fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> deactivateVariant(int variantId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.deactivateVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        variantId: variantId,
      );
      await fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> deleteVariant(int variantId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.deleteVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        variantId: variantId,
      );
      await fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> restoreVariant(int variantId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.restoreVariant(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        variantId: variantId,
      );
      await fetchVariants();
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> reorderVariants(List<int> orderedIds) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final currentVariants = List<CatalogItemVariantSummaryResponse>.from(state.variants);
      final reorderedVariants = <CatalogItemVariantSummaryResponse>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final variant = currentVariants.firstWhere((v) => v.id == orderedIds[i]);
        reorderedVariants.add(variant.copyWith(orderIndex: i));
      }
      state = state.copyWith(variants: reorderedVariants);

      await _repo.reorderVariants(
        businessId: _arg.businessId,
        itemId: _arg.itemId,
        orderedVariantIds: orderedIds,
      );
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      await fetchVariants(); // revert
    }
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is List) return message.join(', ');
        if (message is String) return message;
        final err = data['error'];
        if (err is List) return err.join(', ');
        if (err is String) return err;
        return 'Something went wrong';
      }
      return 'Network error. Check your connection.';
    }
    return error.toString();
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final catalogItemVariantControllerProvider =
    StateNotifierProvider.family<
      CatalogItemVariantController,
      CatalogItemVariantListState,
      VariantArg
    >((ref, arg) {
  return CatalogItemVariantController(ref, arg);
},
);
