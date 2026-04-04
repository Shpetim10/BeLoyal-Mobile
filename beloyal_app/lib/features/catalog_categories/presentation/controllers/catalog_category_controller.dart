import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/catalog_category_repository.dart';
import '../../data/models/catalog_category.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../../../features/auth/domain/models/auth_user.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class CatalogCategoryListState {
  const CatalogCategoryListState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter = CategoryStatusFilter.all,
    this.isSubmitting = false,
    this.createError,
    this.lastCreatedId,
  });

  final List<CatalogCategory> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final CategoryStatusFilter statusFilter;

  // Form state
  final bool isSubmitting;
  final String? createError;
  final int? lastCreatedId;

  // ── Derived ───────────────────────────────────────────────────────────────

  List<CatalogCategory> get filteredCategories {
    var list = categories;

    // Status filter
    list = switch (statusFilter) {
      CategoryStatusFilter.all => list,
      CategoryStatusFilter.active =>
        list.where((c) => c.status == CategoryStatus.active).toList(),
      CategoryStatusFilter.inactive =>
        list.where((c) => c.status == CategoryStatus.inactive).toList(),
    };

    // Search filter (case-insensitive, on name + description)
    if (searchQuery.trim().isNotEmpty) {
      final query = searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(query) ||
              (c.description?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return list;
  }

  bool get isEmpty => filteredCategories.isEmpty;
  bool get hasError => error != null;

  CatalogCategoryListState copyWith({
    List<CatalogCategory>? categories,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    CategoryStatusFilter? statusFilter,
    bool? isSubmitting,
    String? createError,
    bool clearCreateError = false,
    int? lastCreatedId,
    bool clearLastCreatedId = false,
  }) {
    return CatalogCategoryListState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      createError:
          clearCreateError ? null : (createError ?? this.createError),
      lastCreatedId: clearLastCreatedId
          ? null
          : (lastCreatedId ?? this.lastCreatedId),
    );
  }
}

// ── Controller ────────────────────────────────────────────────────────────────

class CatalogCategoryController
    extends Notifier<CatalogCategoryListState> {
  @override
  CatalogCategoryListState build() => const CatalogCategoryListState();

  CatalogCategoryRepository get _repo =>
      ref.read(catalogCategoryRepositoryProvider);

  // ── Role helpers ──────────────────────────────────────────────────────────

  bool get isAdmin =>
      ref.read(sessionControllerProvider)?.activeRole ==
      UserRole.businessAdmin;

  // ── Fetch ─────────────────────────────────────────────────────────────────

  Future<void> fetchCategories(int businessId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getAll(businessId: businessId);
      // Sort by orderIndex for correct display order
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(categories: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _extractMessage(e),
      );
    }
  }

  // ── Local Filters ─────────────────────────────────────────────────────────

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateStatusFilter(CategoryStatusFilter filter) {
    state = state.copyWith(statusFilter: filter);
  }

  // ── Create ────────────────────────────────────────────────────────────────

  /// Returns the created [CatalogCategory] on success, or null on failure.
  Future<CatalogCategory?> createCategory({
    required int businessId,
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearCreateError: true);
    try {
      final created = await _repo.create(
        businessId: businessId,
        name: name,
        description: description,
      );

      // Optimistically prepend the new category and refresh list
      await fetchCategories(businessId);

      state = state.copyWith(
        isSubmitting: false,
        lastCreatedId: created.id,
      );
      return created;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        createError: _extractMessage(e),
      );
      return null;
    }
  }

  /// Clears `lastCreatedId` after auto-scroll has been performed.
  void clearLastCreatedId() {
    state = state.copyWith(clearLastCreatedId: true);
  }

  // ── Update (ready — awaiting backend endpoint) ────────────────────────────
  // TODO: Activate when PUT /catalog-category/{id} endpoint is live.
  Future<CatalogCategory?> updateCategory({
    required int businessId,
    required int categoryId,
    required String name,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true, clearCreateError: true);
    try {
      final updated = await _repo.update(
        businessId: businessId,
        categoryId: categoryId,
        name: name,
        description: description,
      );
      // Replace in list
      final newList = state.categories.map((c) {
        return c.id == categoryId ? updated : c;
      }).toList();
      state = state.copyWith(categories: newList, isSubmitting: false);
      return updated;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        createError: _extractMessage(e),
      );
      return null;
    }
  }

  // ── Activate (ready — awaiting backend endpoint) ──────────────────────────
  // TODO: Activate when PATCH /catalog-category/{id}/activate endpoint is live.
  Future<void> activateCategory({
    required int businessId,
    required int categoryId,
  }) async {
    try {
      final updated = await _repo.activate(
        businessId: businessId,
        categoryId: categoryId,
      );
      _replaceInList(updated);
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
    }
  }

  // ── Deactivate (ready — awaiting backend endpoint) ────────────────────────
  // TODO: Activate when PATCH /catalog-category/{id}/deactivate endpoint is live.
  Future<void> deactivateCategory({
    required int businessId,
    required int categoryId,
  }) async {
    try {
      final updated = await _repo.deactivate(
        businessId: businessId,
        categoryId: categoryId,
      );
      _replaceInList(updated);
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
    }
  }

  // ── Delete (ready — awaiting backend endpoint) ────────────────────────────
  // TODO: Activate when DELETE /catalog-category/{id} endpoint is live.
  Future<bool> deleteCategory({
    required int businessId,
    required int categoryId,
  }) async {
    try {
      await _repo.delete(businessId: businessId, categoryId: categoryId);
      final newList =
          state.categories.where((c) => c.id != categoryId).toList();
      state = state.copyWith(categories: newList);
      return true;
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
      return false;
    }
  }

  // ── Reorder (ready — awaiting backend endpoint) ───────────────────────────
  // TODO: Activate when PUT /catalog-category/reorder endpoint is live.
  Future<void> reorderCategories({
    required int businessId,
    required List<int> orderedIds,
  }) async {
    try {
      final updated =
          await _repo.reorder(businessId: businessId, orderedIds: orderedIds);
      updated.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      state = state.copyWith(categories: updated);
    } catch (e) {
      state = state.copyWith(error: _extractMessage(e));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _replaceInList(CatalogCategory updated) {
    final newList = state.categories.map((c) {
      return c.id == updated.id ? updated : c;
    }).toList();
    state = state.copyWith(categories: newList);
  }

  String _extractMessage(dynamic error) {
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

// ── Provider ──────────────────────────────────────────────────────────────────

final catalogCategoryControllerProvider =
    NotifierProvider<CatalogCategoryController, CatalogCategoryListState>(
  CatalogCategoryController.new,
);
