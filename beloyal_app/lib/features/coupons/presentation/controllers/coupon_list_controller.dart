import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/coupon_repository.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';

class CouponListState {
  const CouponListState({
    this.coupons = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.statusFilter,
    this.typeFilter,
    this.sortBy = 'createdAt',
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
  final CouponStatus? statusFilter;
  final CouponType? typeFilter;
  final String sortBy;
  final String sortDirection;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final bool isSubmitting;
  final String? actionError;

  bool get hasMore => currentPage < totalPages - 1;

  CouponListState copyWith({
    List<CouponSummary>? coupons,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? searchQuery,
    CouponStatus? statusFilter,
    bool clearStatusFilter = false,
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
    return CouponListState(
      coupons: coupons ?? this.coupons,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      typeFilter: clearTypeFilter ? null : (typeFilter ?? this.typeFilter),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}

class CouponListController extends Notifier<CouponListState> {
  @override
  CouponListState build() => const CouponListState();

  CouponRepository get _repo => ref.read(couponRepositoryProvider);

  Future<void> fetchCoupons(int businessId, {bool reset = true}) async {
    if (reset) {
      state = state.copyWith(isLoading: true, clearError: true, currentPage: 0);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final page = reset ? 0 : state.currentPage + 1;
      final result = await _repo.listCoupons(
        businessId: businessId,
        status: state.statusFilter,
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
        isSubmitting: false,
        currentPage: result.number,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        isSubmitting: false,
        error: _extractMessage(e),
      );
    }
  }

  Future<void> changeStatus({
    required int businessId,
    required int couponId,
    required CouponStatus status,
  }) async {
    state = state.copyWith(isSubmitting: true, clearActionError: true);
    try {
      await _repo.changeCouponStatus(
        businessId: businessId,
        couponId: couponId,
        status: status,
      );
      await fetchCoupons(businessId);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        actionError: _extractMessage(e),
      );
    }
  }

  Future<void> changeVisibility({
    required int businessId,
    required int couponId,
    required CouponVisibility visibility,
  }) async {
    state = state.copyWith(isSubmitting: true, clearActionError: true);
    try {
      await _repo.updateCoupon(
        businessId: businessId,
        couponId: couponId,
        updates: {'visibility': visibility.backendValue},
      );
      await fetchCoupons(businessId);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        actionError: _extractMessage(e),
      );
    }
  }

  Future<bool> deleteCoupon({
    required int businessId,
    required int couponId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearActionError: true);
    try {
      await _repo.deleteCoupon(businessId: businessId, couponId: couponId);
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

  Future<bool> archiveCoupon({
    required int businessId,
    required int couponId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearActionError: true);
    try {
      await _repo.archiveCoupon(businessId: businessId, couponId: couponId);
      await fetchCoupons(businessId);
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

  void setStatusFilter(CouponStatus? status) {
    state = status == null
        ? state.copyWith(clearStatusFilter: true)
        : state.copyWith(statusFilter: status);
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
        final code = (data['code'] ?? data['errorCode'])?.toString();
        final mapped = _mapBackendErrorCode(code);
        if (mapped != null) return mapped;
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

  String? _mapBackendErrorCode(String? code) => switch (code) {
    'CATEGORY_NOT_ACTIVE' =>
      'The selected category is no longer active. Please select another category.',
    'PRODUCT_NOT_ACTIVE' =>
      'The selected product is no longer active. Please select another product.',
    'VARIANT_NOT_ACTIVE' =>
      'The selected variant is no longer active. Please select another variant.',
    'INVALID_POINTS_COST' => 'Points cost must be greater than 0.',
    'INVALID_DATE_RANGE' => 'End date must be after start date.',
    _ => null,
  };
}

final couponListControllerProvider =
    NotifierProvider<CouponListController, CouponListState>(
      CouponListController.new,
    );
