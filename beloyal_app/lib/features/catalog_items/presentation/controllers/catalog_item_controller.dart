import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalog_item_repository.dart';
import '../../data/models/catalog_item_detail_response.dart';
import '../../data/models/catalog_item_short_response.dart';
import '../../data/models/catalog_item_short_response.dart';
import '../../data/models/catalog_item_status.dart';
import '../../data/models/catalog_item_create_request.dart';

class CatalogItemListState {
  const CatalogItemListState({
    this.items = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.categoryIdFilter,
    this.categoryNameFilter,
    this.isSubmitting = false,
  });

  final List<CatalogItemShortResponse> items;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final int? categoryIdFilter;
  final String? categoryNameFilter;
  final bool isSubmitting;

  List<CatalogItemShortResponse> get filteredItems {
    var list = items;

    // Filter by category if a filter is active
    if (categoryNameFilter != null) {
      list = list.where((item) => item.categoryName == categoryNameFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list.where((item) => item.name.toLowerCase().contains(query)).toList();
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
    bool? isSubmitting,
  }) {
    return CatalogItemListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      categoryIdFilter: clearCategoryFilter ? null : (categoryIdFilter ?? this.categoryIdFilter),
      categoryNameFilter: clearCategoryFilter ? null : (categoryNameFilter ?? this.categoryNameFilter),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class CatalogItemController extends Notifier<CatalogItemListState> {
  @override
  CatalogItemListState build() => const CatalogItemListState();

  CatalogItemRepository get _repo => ref.read(catalogItemRepositoryProvider);

  Future<void> fetchItems(int businessId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAll(businessId: businessId);
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(items: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _extractMessage(e));
    }
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> createItem({
    required int businessId,
    required int categoryId,
    required CatalogItemCreateRequest request,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.createItem(businessId: businessId, categoryId: categoryId, request: request);
      await fetchItems(businessId); // Refresh list
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
      await _repo.updateItem(businessId: businessId, itemId: itemId, request: request);
      await fetchItems(businessId); // Refresh list
      ref.invalidate(catalogItemDetailProvider((businessId: businessId, itemId: itemId)));
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
      rethrow;
    }
  }

  void filterByCategory(int? categoryId, String? categoryName) {
    state = state.copyWith(
      categoryIdFilter: categoryId,
      categoryNameFilter: categoryName,
      clearCategoryFilter: categoryId == null,
    );
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
      // Remove from deleted list if we were in the trash view
      final newList = state.items.where((i) => i.id != itemId).toList();
      state = state.copyWith(items: newList, isSubmitting: false);
      ref.invalidate(deletedCatalogItemsProvider(businessId));
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _extractMessage(e));
    }
  }

  Future<void> moveCategory(int businessId, int itemId, int categoryId, String newCategoryName) async {
    state = state.copyWith(isSubmitting: true);
    try {
      await _repo.moveCategory(businessId: businessId, itemId: itemId, categoryId: categoryId);
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

  Future<void> reorderItems(int businessId, int categoryId, List<int> orderedIds) async {
    try {
      // Optimistic update locally
      final currentItems = List<CatalogItemShortResponse>.from(state.items);
      final reorderedItems = <CatalogItemShortResponse>[];
      for (int i = 0; i < orderedIds.length; i++) {
        final item = currentItems.firstWhere((element) => element.id == orderedIds[i]);
        reorderedItems.add(item.copyWith(orderIndex: i));
      }
      state = state.copyWith(items: reorderedItems);

      await _repo.reorder(businessId: businessId, categoryId: categoryId, orderedIds: orderedIds);
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
      await fetchItems(businessId); // Revert on failure
    }
  }

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
        if (message is List) {
          return message.join(', ');
        }
        if (message is String) return message;

        final err = data['error'];
        if (err is List) {
          return err.join(', ');
        }
        if (err is String) return err;

        return 'Something went wrong';
      }
      return 'Network error. Check your connection.';
    }
    return error.toString();
  }
}

final catalogItemControllerProvider =
    NotifierProvider<CatalogItemController, CatalogItemListState>(
  CatalogItemController.new,
);

// Detail provider
final catalogItemDetailProvider = FutureProvider.family.autoDispose<CatalogItemDetailResponse, ({int businessId, int itemId})>(
  (ref, args) {
    return ref.read(catalogItemRepositoryProvider).getById(businessId: args.businessId, itemId: args.itemId);
  },
);

// Deleted items provider
final deletedCatalogItemsProvider = FutureProvider.family.autoDispose<List<CatalogItemShortResponse>, int>(
  (ref, businessId) {
    return ref.read(catalogItemRepositoryProvider).getDeleted(businessId: businessId);
  },
);
