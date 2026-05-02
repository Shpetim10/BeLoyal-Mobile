import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog_item_repository.dart';
import '../../data/models/catalog_item_create_request.dart';
import '../../data/models/catalog_item_detail_response.dart';
import '../../data/models/catalog_item_short_response.dart';
import '../../data/models/catalog_item_status.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/domain/models/auth_user.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum CatalogItemStatusFilter { all, active, inactive }

class CatalogItemListState {
  const CatalogItemListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryIdFilter,
    this.categoryNameFilter,
    this.statusFilter = CatalogItemStatusFilter.all,
    this.isSubmitting = false,
  });

  final List<CatalogItemShortResponse> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int? categoryIdFilter;
  final String? categoryNameFilter;
  final CatalogItemStatusFilter statusFilter;
  final bool isSubmitting;

  List<CatalogItemShortResponse> get filteredItems {
    var list = items;

    // Category filter
    if (categoryIdFilter != null) {
      list = list.where((item) => item.categoryId == categoryIdFilter).toList();
    }

    // Status filter
    list = switch (statusFilter) {
      CatalogItemStatusFilter.all => list,
      CatalogItemStatusFilter.active =>
        list.where((i) => i.status == CatalogItemStatus.active).toList(),
      CatalogItemStatusFilter.inactive =>
        list.where((i) => i.status == CatalogItemStatus.inactive).toList(),
    };

    // Search filter
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list
          .where(
            (i) =>
                i.name.toLowerCase().contains(query) ||
                (i.categoryName?.toLowerCase().contains(query) ?? false),
          )
          .toList();
    }

    return list;
  }

  CatalogItemListState copyWith({
    List<CatalogItemShortResponse>? items,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    int? categoryIdFilter,
    String? categoryNameFilter,
    bool clearCategoryFilter = false,
    CatalogItemStatusFilter? statusFilter,
    bool? isSubmitting,
  }) {
    return CatalogItemListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      categoryIdFilter: clearCategoryFilter
          ? null
          : (categoryIdFilter ?? this.categoryIdFilter),
      categoryNameFilter: clearCategoryFilter
          ? null
          : (categoryNameFilter ?? this.categoryNameFilter),
      statusFilter: statusFilter ?? this.statusFilter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class CatalogItemController extends Notifier<CatalogItemListState> {
  @override
  CatalogItemListState build() {
    return const CatalogItemListState();
  }

  CatalogItemRepository get _repo => ref.read(catalogItemRepositoryProvider);

  bool get isAdmin =>
      ref.read(sessionControllerProvider)?.activeRole == UserRole.businessAdmin;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> fetchItems(int businessId, {int? categoryId}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAll(
        businessId: businessId,
        categoryId: categoryId,
      );
      // Sort by orderIndex
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateStatusFilter(CatalogItemStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  void filterByCategory(int? categoryId, String? categoryName) {
    state = state.copyWith(
      categoryIdFilter: categoryId,
      categoryNameFilter: categoryName,
      clearCategoryFilter: categoryId == null,
    );
  }

  Future<void> createItem({
    required int businessId,
    required int categoryId,
    required CatalogItemCreateRequest request,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.createItem(
        businessId: businessId,
        categoryId: categoryId,
        request: request,
      );
      await fetchItems(businessId, categoryId: categoryId);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      rethrow;
    }
  }

  Future<void> updateItem({
    required int businessId,
    required int itemId,
    required CatalogItemCreateRequest request,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.updateItem(
        businessId: businessId,
        itemId: itemId,
        request: request,
      );
      // We can't easily refresh the whole list without categoryId,
      // but we can update the item in the list if we find it.
      // For now, let's just invalidate the detail and let the caller handle it.
      ref.invalidate(
        catalogItemDetailProvider((businessId: businessId, itemId: itemId)),
      );
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      rethrow;
    }
  }

  Future<void> activateItem(int businessId, int itemId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.activate(businessId: businessId, itemId: itemId);
      _updateItemStatus(itemId, CatalogItemStatus.active);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> deactivateItem(int businessId, int itemId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.deactivate(businessId: businessId, itemId: itemId);
      _updateItemStatus(itemId, CatalogItemStatus.inactive);
      state = state.copyWith(isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> deleteItem(int businessId, int itemId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.delete(businessId: businessId, itemId: itemId);
      final newList = state.items.where((i) => i.id != itemId).toList();
      state = state.copyWith(items: newList, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> restoreItem(int businessId, int itemId) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.restore(businessId: businessId, itemId: itemId);
      final newList = state.items.where((i) => i.id != itemId).toList();
      state = state.copyWith(items: newList, isSubmitting: false);
      ref.invalidate(deletedCatalogItemsProvider(businessId));
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> moveCategory(
    int businessId,
    int itemId,
    int categoryId,
    String newCategoryName,
  ) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.moveCategory(
        businessId: businessId,
        itemId: itemId,
        categoryId: categoryId,
      );
      final newList = state.items.map((i) {
        if (i.id == itemId) {
          return i.copyWith(categoryName: newCategoryName);
        }
        return i;
      }).toList();
      state = state.copyWith(items: newList, isSubmitting: false);
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> reorderItems(
    int businessId,
    int categoryId,
    List<int> orderedIds,
  ) async {
    try {
      // Optimistic update locally
      final currentItems = List<CatalogItemShortResponse>.from(state.items);
      final reorderedItems = <CatalogItemShortResponse>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final item = currentItems.firstWhere(
          (element) => element.id == orderedIds[i],
        );
        reorderedItems.add(item.copyWith(orderIndex: i));
      }
      state = state.copyWith(items: reorderedItems);

      await _repo.reorder(
        businessId: businessId,
        categoryId: categoryId,
        orderedIds: orderedIds,
      );
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
      await fetchItems(businessId, categoryId: categoryId); // Revert on failure
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _updateItemStatus(int itemId, CatalogItemStatus status) {
    final newList = state.items.map((i) {
      if (i.id == itemId) {
        return i.copyWith(status: status);
      }
      return i;
    }).toList();
    state = state.copyWith(items: newList);
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

// ── Providers ─────────────────────────────────────────────────────────────────

final catalogItemControllerProvider =
    NotifierProvider<CatalogItemController, CatalogItemListState>(
      CatalogItemController.new,
    );

final catalogItemDetailProvider = FutureProvider.family
    .autoDispose<CatalogItemDetailResponse, ({int businessId, int itemId})>((
      ref,
      args,
    ) {
      return ref
          .read(catalogItemRepositoryProvider)
          .getById(businessId: args.businessId, itemId: args.itemId);
    });

final deletedCatalogItemsProvider = FutureProvider.family
    .autoDispose<List<CatalogItemShortResponse>, int>((ref, businessId) {
      return ref
          .read(catalogItemRepositoryProvider)
          .getDeleted(businessId: businessId);
    });
