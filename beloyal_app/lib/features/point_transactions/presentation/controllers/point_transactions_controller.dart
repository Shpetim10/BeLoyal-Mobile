import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/models/point_transaction_list_dto.dart';
import '../../data/point_transactions_repository.dart';

// --- Filters ---

enum TxTypeFilter {
  all,
  earnBill,
  redeemDiscount,
  redeemOffer,
  expire,
  adjustmentPlus,
  adjustmentMinus,
  reversal,
}

extension TxTypeFilterX on TxTypeFilter {
  String get displayName {
    switch (this) {
      case TxTypeFilter.all:
        return 'All';
      case TxTypeFilter.earnBill:
        return 'Earn';
      case TxTypeFilter.redeemDiscount:
        return 'Redeem';
      case TxTypeFilter.redeemOffer:
        return 'Redeem Offer';
      case TxTypeFilter.expire:
        return 'Expire';
      case TxTypeFilter.adjustmentPlus:
        return 'Adj +';
      case TxTypeFilter.adjustmentMinus:
        return 'Adj -';
      case TxTypeFilter.reversal:
        return 'Reversal';
    }
  }

  String get apiValue {
    switch (this) {
      case TxTypeFilter.all:
        return 'ALL';
      case TxTypeFilter.earnBill:
        return 'EARN_BILL';
      case TxTypeFilter.redeemDiscount:
        return 'REDEEM_DISCOUNT';
      case TxTypeFilter.redeemOffer:
        return 'REDEEM_OFFER';
      case TxTypeFilter.expire:
        return 'EXPIRE';
      case TxTypeFilter.adjustmentPlus:
        return 'ADJUSTMENT_PLUS';
      case TxTypeFilter.adjustmentMinus:
        return 'ADJUSTMENT_MINUS';
      case TxTypeFilter.reversal:
        return 'REVERSAL';
    }
  }
}

class TxSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;
}

final txSearchQueryProvider = NotifierProvider<TxSearchQueryNotifier, String>(
  TxSearchQueryNotifier.new,
);

class TxTypeFilterNotifier extends Notifier<TxTypeFilter> {
  @override
  TxTypeFilter build() => TxTypeFilter.all;

  void updateFilter(TxTypeFilter value) => state = value;
}

final txTypeFilterProvider = NotifierProvider<TxTypeFilterNotifier, TxTypeFilter>(
  TxTypeFilterNotifier.new,
);

class TxEmployeeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void updateEmployee(String? employeeName) => state = employeeName;
}

final txEmployeeFilterProvider = NotifierProvider<TxEmployeeFilterNotifier, String?>(
  TxEmployeeFilterNotifier.new,
);

class TxDateRangeNotifier extends Notifier<DateTimeRange?> {
  @override
  DateTimeRange? build() => null;

  void updateDateRange(DateTimeRange? range) => state = range;
}

final txDateRangeProvider = NotifierProvider<TxDateRangeNotifier, DateTimeRange?>(
  TxDateRangeNotifier.new,
);

// --- Main Controller ---

class PointTransactionsController extends AsyncNotifier<List<PointTransactionBusinessListViewDto>> {
  @override
  Future<List<PointTransactionBusinessListViewDto>> build() async {
    return _fetchTransactions();
  }

  Future<List<PointTransactionBusinessListViewDto>> _fetchTransactions() async {
    final session = ref.watch(sessionControllerProvider);
    final businessId = session?.activeBusinessId ?? 0;
    if (businessId == 0) return [];
    return ref.read(pointTransactionsRepositoryProvider).fetchTransactions(businessId);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchTransactions);
  }
}

final pointTransactionsControllerProvider = AsyncNotifierProvider<
    PointTransactionsController, List<PointTransactionBusinessListViewDto>>(
  PointTransactionsController.new,
);

// --- Derived Providers ---

final uniqueEmployeeNamesProvider = Provider<List<String>>((ref) {
  final transactions = ref.watch(pointTransactionsControllerProvider).value ?? [];
  final names = transactions.map((t) => t.businessMemberFullName).toSet().toList();
  names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return names;
});

final activeFilterCountProvider = Provider<int>((ref) {
  int count = 0;
  if (ref.watch(txSearchQueryProvider).isNotEmpty) count++;
  if (ref.watch(txTypeFilterProvider) != TxTypeFilter.all) count++;
  if (ref.watch(txEmployeeFilterProvider) != null) count++;
  if (ref.watch(txDateRangeProvider) != null) count++;
  return count;
});

final filteredGroupedTransactionsProvider =
    Provider<Map<DateTime, List<PointTransactionBusinessListViewDto>>>((ref) {
  final transactions = ref.watch(pointTransactionsControllerProvider).value ?? [];
  final q = ref.watch(txSearchQueryProvider).toLowerCase().trim();
  final typeFilter = ref.watch(txTypeFilterProvider);
  final employeeFilter = ref.watch(txEmployeeFilterProvider);
  final dateRange = ref.watch(txDateRangeProvider);

  // 1. Filter
  var result = transactions.where((tx) {
    // Type Filter
    if (typeFilter != TxTypeFilter.all && tx.type != typeFilter.apiValue) {
      return false;
    }

    // Employee Filter
    if (employeeFilter != null && tx.businessMemberFullName != employeeFilter) {
      return false;
    }

    // Date Range Filter
    if (dateRange != null) {
      // Create a DateTime representing the start of the required start date, 
      // and the end of the required end date to cover the full days.
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
  final Map<DateTime, List<PointTransactionBusinessListViewDto>> grouped = LinkedHashMap();
  
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
