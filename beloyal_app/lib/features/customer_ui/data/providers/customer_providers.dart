import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_home_dto.dart';
import '../repositories/customer_repository.dart';
import '../../domain/models/customer_data_source.dart';
import '../../domain/models/customer_ui_models.dart';

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

final customerBusinessDetailProvider = FutureProvider.autoDispose
    .family<CustomerBusinessDetail, int>((ref, businessId) async {
      final dto = await ref
          .read(customerRepositoryProvider)
          .fetchBusinessDetail(businessId);
      return mapBusinessDetailDto(dto);
    });

class CustomerProfileDetailsNotifier
    extends AsyncNotifier<CustomerProfileDetailsDto> {
  @override
  Future<CustomerProfileDetailsDto> build() {
    return ref.read(customerRepositoryProvider).fetchProfileDetails();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider).fetchProfileDetails(),
    );
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    required String phone,
    required String city,
    required String country,
    required String? gender,
    required DateTime? birthDate,
    bool? notificationEnabled,
  }) async {
    await ref
        .read(customerRepositoryProvider)
        .updateProfile(
          firstName: firstName,
          lastName: lastName,
          username: username,
          phone: phone,
          city: city,
          country: country,
          gender: gender,
          birthDate: birthDate,
          notificationEnabled: notificationEnabled,
        );
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider).fetchProfileDetails(),
    );
  }

  Future<void> updateNotificationEnabled(bool enabled) async {
    await ref
        .read(customerRepositoryProvider)
        .updateNotificationEnabled(enabled);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(customerRepositoryProvider).fetchProfileDetails(),
    );
  }
}

final customerProfileDetailsProvider =
    AsyncNotifierProvider<
      CustomerProfileDetailsNotifier,
      CustomerProfileDetailsDto
    >(CustomerProfileDetailsNotifier.new);
