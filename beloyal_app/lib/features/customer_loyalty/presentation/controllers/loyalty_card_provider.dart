import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/loyalty_card_repository.dart';
import '../../data/models/loyalty_card_dto.dart';

/// Loads and caches the customer's loyalty card data for the current session.
///
/// - First access → fetches from `/customer/me/loyalty-card`.
/// - Subsequent reads within the same session → returns the cached value without
///   a new network call (Riverpod keeps the provider alive as long as there is
///   a listener, i.e. as long as the customer dashboard is mounted).
/// - Call `ref.invalidate(loyaltyCardProvider)` on logout to clear the cache.
class LoyaltyCardNotifier extends AsyncNotifier<LoyaltyCardDto> {
  @override
  Future<LoyaltyCardDto> build() async {
    final repo = ref.read(loyaltyCardRepositoryProvider);
    return repo.fetchMyCard();
  }

  /// Force-refresh from the network (e.g. pull-to-refresh).
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(loyaltyCardRepositoryProvider).fetchMyCard(),
    );
  }
}

final loyaltyCardProvider =
    AsyncNotifierProvider<LoyaltyCardNotifier, LoyaltyCardDto>(
      LoyaltyCardNotifier.new,
    );
