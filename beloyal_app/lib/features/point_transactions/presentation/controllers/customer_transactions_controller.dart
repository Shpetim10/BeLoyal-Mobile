import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/point_transaction_customer_list_dto.dart';
import '../../data/point_transactions_repository.dart';

class CustomerTransactionsController extends AsyncNotifier<List<PointTransactionCustomerAllListViewDto>> {
  @override
  FutureOr<List<PointTransactionCustomerAllListViewDto>> build() async {
    return _fetchTransactions();
  }

  Future<List<PointTransactionCustomerAllListViewDto>> _fetchTransactions() async {
    final repository = ref.read(pointTransactionsRepositoryProvider);
    return repository.fetchCustomerTransactions();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchTransactions());
  }
}

final customerTransactionsControllerProvider =
    AsyncNotifierProvider<CustomerTransactionsController, List<PointTransactionCustomerAllListViewDto>>(
  () => CustomerTransactionsController(),
);
