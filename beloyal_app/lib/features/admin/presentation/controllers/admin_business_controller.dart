import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_business_dtos.dart';
import '../../data/repositories/admin_business_repository.dart';

// ── List Provider ────────────────────────────────────────────────────────────

class AdminAllBusinessesController extends AsyncNotifier<List<BusinessListViewDto>> {
  @override
  FutureOr<List<BusinessListViewDto>> build() async {
    return _fetchBusinesses();
  }

  Future<List<BusinessListViewDto>> _fetchBusinesses() async {
    final repo = ref.read(adminBusinessRepositoryProvider);
    return repo.getAllBusinesses();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchBusinesses());
  }
}

final adminAllBusinessesProvider =
    AsyncNotifierProvider<AdminAllBusinessesController, List<BusinessListViewDto>>(
  () => AdminAllBusinessesController(),
);

// ── Filters ──────────────────────────────────────────────────────────────────

class AdminBusinessSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String query) {
    state = query;
  }
}

final adminBusinessSearchQueryProvider =
    NotifierProvider<AdminBusinessSearchQueryNotifier, String>(AdminBusinessSearchQueryNotifier.new);

enum AdminBusinessStatusFilter { all, active, pending, rejected }

class AdminBusinessStatusFilterNotifier extends Notifier<AdminBusinessStatusFilter> {
  @override
  AdminBusinessStatusFilter build() => AdminBusinessStatusFilter.all;

  void updateFilter(AdminBusinessStatusFilter filter) {
    state = filter;
  }
}

final adminBusinessStatusFilterProvider =
    NotifierProvider<AdminBusinessStatusFilterNotifier, AdminBusinessStatusFilter>(
        AdminBusinessStatusFilterNotifier.new);

// ── Filtered List ────────────────────────────────────────────────────────────

final adminFilteredBusinessesProvider = Provider<List<BusinessListViewDto>>((ref) {
  final asyncBusinesses = ref.watch(adminAllBusinessesProvider);
  final searchQuery = ref.watch(adminBusinessSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(adminBusinessStatusFilterProvider);

  if (asyncBusinesses.value == null) return [];

  return asyncBusinesses.value!.where((biz) {
    // 1. Search Filter (by name or email or phone)
    final matchesSearch = biz.businessName.toLowerCase().contains(searchQuery) ||
        biz.businessEmail.toLowerCase().contains(searchQuery) ||
        biz.businessPhone.toLowerCase().contains(searchQuery);

    if (!matchesSearch) return false;

    // 2. Status Filter
    if (statusFilter == AdminBusinessStatusFilter.all) return true;

    final status = biz.businessStatus.toUpperCase();
    switch (statusFilter) {
      case AdminBusinessStatusFilter.active:
        return status == 'ACTIVE';
      case AdminBusinessStatusFilter.pending:
        return status == 'PENDING' || status == 'UNDER_REVIEW';
      case AdminBusinessStatusFilter.rejected:
        return status == 'REJECTED';
      default:
        return true;
    }
  }).toList();
});

// ── Details Provider ─────────────────────────────────────────────────────────

final adminBusinessDetailsProvider = FutureProvider.family<BusinessDetailsDto, int>((ref, businessId) async {
  final repo = ref.read(adminBusinessRepositoryProvider);
  return repo.getBusinessDetails(businessId);
});

// ── Lifecycle Controller ──────────────────────────────────────────────────────

class AdminBusinessLifecycleController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> suspend(int businessId, String reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminBusinessRepositoryProvider).suspendBusiness(businessId, reason),
    );
    if (!state.hasError) {
      ref.invalidate(adminBusinessDetailsProvider(businessId));
      ref.invalidate(adminAllBusinessesProvider);
    }
  }

  Future<void> ban(int businessId, String reason) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminBusinessRepositoryProvider).banBusiness(businessId, reason),
    );
    if (!state.hasError) {
      ref.invalidate(adminBusinessDetailsProvider(businessId));
      ref.invalidate(adminAllBusinessesProvider);
    }
  }

  Future<void> reactivate(int businessId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminBusinessRepositoryProvider).reactivateBusiness(businessId),
    );
    if (!state.hasError) {
      ref.invalidate(adminBusinessDetailsProvider(businessId));
      ref.invalidate(adminAllBusinessesProvider);
    }
  }

  Future<void> delete(int businessId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(adminBusinessRepositoryProvider).deleteBusiness(businessId),
    );
  }
}

final adminBusinessLifecycleProvider =
    AsyncNotifierProvider<AdminBusinessLifecycleController, void>(
  AdminBusinessLifecycleController.new,
);

// ── Platform Users Provider ───────────────────────────────────────────────────

final adminPlatformUsersProvider =
    FutureProvider<List<PlatformUserSummaryDto>>((ref) async {
  return ref.read(adminBusinessRepositoryProvider).getPlatformUsers();
});

final adminUserSearchQueryProvider = NotifierProvider<_UserSearchNotifier, String>(_UserSearchNotifier.new);

class _UserSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void update(String q) => state = q;
}
