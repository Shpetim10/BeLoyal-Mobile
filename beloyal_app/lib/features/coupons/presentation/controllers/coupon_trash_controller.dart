import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/coupon_repository.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';

class CouponTrashState {
  const CouponTrashState({
    this.coupons = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.typeFilter,
    this.sortBy = 'deletedAt',
    this.sortDirection = 'DESC',
    this.currentPage = 0,
    this.totalPages = 1,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.actionError,
  });

  final List<CouponSummary> coupons;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final CouponType? typeFilter;
  final String sortBy;
  final String sortDirection;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? actionError;

  bool get hasMore => currentPage < totalPages - 1;

  CouponTrashState copyWith({
    List<CouponSummary>? coupons,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    CouponType? typeFilter,
    bool clearTypeFilter = false,
    String? sortBy,
    String? sortDirection,
    int? currentPage,
    int? totalPages,
    bool? isLoadingMore,
    bool? isSubmitting,
    String? actionError,
    bool clearActionError = false,
  }) {
    return CouponTrashState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionError:
          clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class CouponTrashController extends Notifier<CouponTrashState> {
  @override
  CouponTrashState build() => const CouponTrashState();

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  Future<void> fetchCoupons(int businessId, {bool reset = true}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true, currentPage: 0);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 0 : state.currentPage + 1;
      final result = await _repo.listTrashedCoupons(
        businessId: businessId,
        type: state.typeFilter,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: page,
        sortBy: state.sortBy,
        sortDirection: state.sortDirection,
      );

      final newCoupons = reset
          ? result.content
          : [...state.coupons, ...result.content];

      state = state.copyWith(
        coupons: newCoupons,
        isLoading: false,
        isLoadingMore: false,
        currentPage: result.number,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: _extractMessage(e),
      );
    }
  }

  Future<bool> restoreFromTrash({
    required int businessId,
    required int couponId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearActionError: true);
    try {
      await _repo.restoreFromTrash(
        businessId: businessId,
        couponId: couponId,
      );
      state = state.copyWith(
        coupons: state.coupons.where((c) => c.id != couponId).toList(),
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        actionError: _extractMessage(e),
      );
      return false;
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setTypeFilter(CouponType? type) {
    state = type == null
        ? state.copyWith(clearTypeFilter: true)
        : state.copyWith(typeFilter: type);
  }

  void setSortBy(String sortBy) {
    state = state.copyWith(sortBy: sortBy);
  }

  void toggleSortDirection() {
    state = state.copyWith(
      sortDirection: state.sortDirection == 'DESC' ? 'ASC' : 'DESC',
    );
  }

  String _extractMessage(dynamic error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return (data['message'] as String?) ?? 'Something went wrong';
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

final couponTrashControllerProvider =
    NotifierProvider<CouponTrashController, CouponTrashState>(
      CouponTrashController.new,
    );
