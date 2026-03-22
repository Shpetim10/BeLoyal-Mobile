import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/point_transaction_staff_list_dto.dart';
import '../../data/point_transactions_repository.dart';
import 'point_transactions_controller.dart' show TxTypeFilter, TxTypeFilterX;

// --- Filters ---
// Reuse TxSearchQueryNotifier, TxTypeFilterNotifier, TxDateRangeNotifier 
// from the main generic controller to avoid duplicate code logic if possible.
// Wait, riverpod providers are global singletons by default. If we share the providers,
// Business Admin and Staff might share filter state if they switch roles without app restart.
// To be safe and isolated, we define Staff-specific filter providers.

class StaffTxSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;
}

final staffTxSearchQueryProvider = NotifierProvider<StaffTxSearchQueryNotifier, String>(
  StaffTxSearchQueryNotifier.new,
);

class StaffTxTypeFilterNotifier extends Notifier<TxTypeFilter> {
  @override
  TxTypeFilter build() => TxTypeFilter.all;

  void updateFilter(TxTypeFilter value) => state = value;
}

final staffTxTypeFilterProvider = NotifierProvider<StaffTxTypeFilterNotifier, TxTypeFilter>(
  StaffTxTypeFilterNotifier.new,
);

class StaffTxDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void updateDateRange(DateTimeRange? range) => state = range;
}

final staffTxDateRangeProvider = NotifierProvider<StaffTxDateRangeNotifier, DateTimeRange?>(
  StaffTxDateRangeNotifier.new,
);

// --- Main Controller ---

class StaffPointTransactionsController extends AsyncNotifier<List<PointTransactionStaffListViewDto>> {
  @override
  Future<List<PointTransactionStaffListViewDto>> build() async {
    return _fetchTransactions();
  }

  Future<List<PointTransactionStaffListViewDto>> _fetchTransactions() async {
    final session = ref.watch(sessionControllerProvider);
    final businessId = session?.activeBusinessId ?? 0;
    if (businessId == 0) return [];
    return ref.read(pointTransactionsRepositoryProvider).fetchStaffTransactions(businessId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }
}

final staffPointTransactionsControllerProvider = AsyncNotifierProvider<
    StaffPointTransactionsController, List<PointTransactionStaffListViewDto>>(
  StaffPointTransactionsController.new,
);

// --- Derived Providers ---

final staffActiveFilterCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(staffTxSearchQueryProvider).isNotEmpty) count++;
  if (ref.watch(staffTxTypeFilterProvider) != TxTypeFilter.all) count++;
  if (ref.watch(staffTxDateRangeProvider) != null) count++;
  return count;
});

final staffFilteredGroupedTransactionsProvider =
    Provider<Map<DateTime, List<PointTransactionStaffListViewDto>>>((ref) {
  final transactions = ref.watch(staffPointTransactionsControllerProvider).value ?? [];
  final q = ref.watch(staffTxSearchQueryProvider).toLowerCase().trim();
  final typeFilter = ref.watch(staffTxTypeFilterProvider);
  final dateRange = ref.watch(staffTxDateRangeProvider);

  // 1. Filter
  var result = transactions.where((tx) {
    // Type Filter
    if (typeFilter != TxTypeFilter.all && tx.type != typeFilter.apiValue) {
      return false;
    }

    // Date Range Filter
    if (dateRange != null) {
      final start = DateTime(dateRange.start.year, dateRange.start.month, dateRange.start.day);
      final end = DateTime(dateRange.end.year, dateRange.end.month, dateRange.end.day, 23, 59, 59);
      if (tx.createdAt.isBefore(start) || tx.createdAt.isAfter(end)) {
        return false;
      }
    }

    // Search Filter
    if (q.isNotEmpty) {
      final name = tx.customerFullName.toLowerCase();
      final refId = (tx.billTransactionReferenceId ?? '').toLowerCase();
      if (!name.contains(q) && !refId.contains(q)) {
        return false;
      }
    }

    return true;
  }).toList();

  // 2. Sort newest first overall to ensure chronological grouping
  result.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  // 3. Group by Date
  final Map<DateTime, List<PointTransactionStaffListViewDto>> grouped = LinkedHashMap();
  
  for (final tx in result) {
    // Normalize to date only (year, month, day)
    final dateKey = DateTime(tx.createdAt.year, tx.createdAt.month, tx.createdAt.day);
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(tx);
  }

  return grouped;
});
