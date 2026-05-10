import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/customer_repository.dart';
import '../../domain/models/customer_data_source.dart';

class CustomerDataNotifier extends AsyncNotifier<CustomerDataSource> {
  @override
  Future<CustomerDataSource> build() {
    return _fetchHome();
  }

  Future<CustomerDataSource> _fetchHome() async {
    final dto = await ref.read(customerRepositoryProvider).fetchHome();
    return CustomerDataSource.fromDto(dto);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchHome);
  }
}

final customerDataProvider =
    AsyncNotifierProvider<CustomerDataNotifier, CustomerDataSource>(
      CustomerDataNotifier.new,
    );
