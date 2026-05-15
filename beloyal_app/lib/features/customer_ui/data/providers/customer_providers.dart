import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
    final repo = ref.read(customerRepositoryProvider);
    final results = await Future.wait([
      repo.fetchHome(),
      repo.fetchMyCoupons().catchError((_) => <CustomerPromotionDto>[]),
    ]);
    final dto = results[0] as CustomerHomeDto;
    final myCoupons = results[1] as List<CustomerPromotionDto>;
    // Build couponId -> qrCode map from the my-coupons endpoint (the only source of qrCode)
    final qrCodeOverrides = <int, String>{
      for (final c in myCoupons)
        if (c.qrCode?.isNotEmpty == true) c.id: c.qrCode!,
    };
    return CustomerDataSource.fromDto(dto, qrCodeOverrides: qrCodeOverrides);
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

final customerCouponDetailProvider = FutureProvider.autoDispose
    .family<CustomerCoupon, int>((ref, couponId) async {
      final repo = ref.read(customerRepositoryProvider);
      final promotionDto = await repo.fetchCouponDetails(couponId);

      // Map the DTO to CustomerCoupon with the full detail data
      final expiresAt =
          promotionDto.expiresAt ??
          DateTime.now().add(const Duration(days: 30));
      final expiresIn =
          promotionDto.expiresIn ?? _calculateExpiresIn(expiresAt);

      return CustomerCoupon(
        id: promotionDto.id,
        businessId: promotionDto.businessId,
        businessName: promotionDto.businessName,
        title: promotionDto.title,
        discountValue: promotionDto.discountValue ?? 0,
        discountDisplay: promotionDto.discountDisplay,
        status: promotionDto.status.toLowerCase(),
        expiresAt: expiresAt,
        pointCost: promotionDto.pointCost,
        gradientColors: const [Color(0xFF1A0535), Color(0xFF9B5DE5)],
        type: promotionDto.promotionType,
        isUsed: promotionDto.isUsed,
        description: promotionDto.description,
        expiresIn: expiresIn,
        termsAndConditions: promotionDto.termsAndConditions ?? '',
        usageLimit: promotionDto.usageLimit,
        usageCount: promotionDto.usageCount,
        customerRedemptionCount: promotionDto.customerRedemptionCount,
        isHot: promotionDto.isHot,
        isOwned: promotionDto.isOwned,
        imageUrl: promotionDto.imageUrl,
        currency: promotionDto.currency,
        isFeatured: promotionDto.isFeatured,
        totalRedemptions: promotionDto.totalRedemptions,
        totalRedemptionLimit: promotionDto.totalRedemptionLimit,
        startDate: DateTime.tryParse(promotionDto.startDate ?? ''),
        customerCouponId: promotionDto.customerCouponId,
        minimumOrderAmount: promotionDto.minimumOrderAmount,
        maximumDiscountAmount: promotionDto.maximumDiscountAmount,
        freeProductCategory: promotionDto.freeProductCategory,
        freeProductName: promotionDto.freeProductName,
        freeProductVariant: promotionDto.freeProductVariant,
        freeProductQuantity: promotionDto.freeProductQuantity,
        redeemedAt: promotionDto.redeemedAt != null
            ? DateTime.tryParse(promotionDto.redeemedAt!)
            : null,
        usedAt: promotionDto.usedAt != null
            ? DateTime.tryParse(promotionDto.usedAt!)
            : null,
        orderId: promotionDto.orderId,
        qrCode: promotionDto.qrCode,
        canRedeem: promotionDto.canRedeem,
        cannotRedeemReason: promotionDto.cannotRedeemReason,
      );
    });

String _calculateExpiresIn(DateTime expiresAt) {
  final now = DateTime.now();
  if (expiresAt.isBefore(now)) {
    final daysAgo = now.difference(expiresAt).inDays;
    return 'Expired ${daysAgo}d ago';
  }

  final hoursLeft = expiresAt.difference(now).inHours;
  if (hoursLeft < 24) {
    return 'Expires in ${hoursLeft}h';
  }

  final daysLeft = expiresAt.difference(now).inDays;
  return 'Expires in ${daysLeft}d';
}

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

// ─── Coupon Redemption ────────────────────────────────────────────────────────

sealed class CouponRedemptionState {
  const CouponRedemptionState();
}

class CouponRedemptionIdle extends CouponRedemptionState {
  const CouponRedemptionIdle();
}

class CouponRedemptionLoading extends CouponRedemptionState {
  const CouponRedemptionLoading();
}

class CouponRedemptionSuccess extends CouponRedemptionState {
  const CouponRedemptionSuccess({
    required this.result,
    required this.couponTitle,
  });
  final CustomerCouponRedemptionDto result;
  final String couponTitle;
}

class CouponRedemptionError extends CouponRedemptionState {
  const CouponRedemptionError(this.message);
  final String message;
}

class CustomerCouponRedemptionNotifier extends Notifier<CouponRedemptionState> {
  @override
  CouponRedemptionState build() => const CouponRedemptionIdle();

  Future<void> redeemCoupon({
    required int couponId,
    required String couponTitle,
  }) async {
    if (state is CouponRedemptionLoading) return;
    state = const CouponRedemptionLoading();
    try {
      final result = await ref
          .read(customerRepositoryProvider)
          .redeemCoupon(couponId);
      state = CouponRedemptionSuccess(result: result, couponTitle: couponTitle);
      // Refresh home data so the customer's coupon list reflects ownership
      ref.read(customerDataProvider.notifier).refresh();
    } on DioException catch (e) {
      state = CouponRedemptionError(_mapDioError(e));
    } catch (_) {
      state = const CouponRedemptionError(
        'Something went wrong. Please try again.',
      );
    }
  }

  void reset() => state = const CouponRedemptionIdle();

  String _mapDioError(DioException e) {
    final status = e.response?.statusCode;
    final message = _extractMessage(e.response?.data);
    if (status == 409) {
      return 'You have already claimed the maximum allowed amount of this coupon.';
    }
    if (status == 422) {
      if (message != null) {
        if (message.contains('expired') || message.contains('Expired')) {
          return 'This coupon has expired.';
        }
        if (message.contains('not yet valid') ||
            message.contains('start date')) {
          return 'This coupon is not yet available.';
        }
        if (message.contains('paused') || message.contains('Paused')) {
          return 'This coupon is currently unavailable.';
        }
        if (message.contains('sold out') ||
            message.contains('limit') ||
            message.contains('Limit')) {
          return 'This coupon is sold out.';
        }
        if (message.contains('points') || message.contains('balance')) {
          return 'You don\'t have enough points to claim this coupon.';
        }
      }
      return 'This coupon is no longer available.';
    }
    if (status == 400) {
      final body = e.response?.data;
      final errorKey = body is Map<String, dynamic>
          ? (body['errorKey']?.toString() ?? body['code']?.toString() ?? '')
          : '';
      final rawPts = body is Map<String, dynamic>
          ? (body['pointsRequired'] ?? body['pointsCost'] ?? body['pointCost'])
          : null;
      final pts = rawPts is num ? rawPts.toInt() : 0;
      switch (errorKey) {
        case 'CouponNotActive':
          return 'This coupon is no longer available.';
        case 'CouponExpired':
          return 'This coupon has expired.';
        case 'CouponSoldOut':
          return 'This coupon is sold out.';
        case 'CustomerRedemptionLimitReached':
          return "You've reached your purchase limit for this coupon.";
        case 'InsufficientPoints':
          return pts > 0
              ? "You don't have enough points. Required: $pts pts."
              : "You don't have enough points.";
        default:
          if (message != null) {
            if (message.contains('sold out') || message.contains('SoldOut')) {
              return 'This coupon is sold out.';
            }
            if (message.contains('limit') &&
                (message.contains('customer') ||
                    message.contains('personal'))) {
              return "You've reached your purchase limit for this coupon.";
            }
            if (message.contains('expired') || message.contains('Expired')) {
              return 'This coupon has expired.';
            }
            if (message.contains('not active') ||
                message.contains('NotActive')) {
              return 'This coupon is no longer available.';
            }
            if (message.contains('points') || message.contains('balance')) {
              return pts > 0
                  ? "You don't have enough points. Required: $pts pts."
                  : "You don't have enough points.";
            }
          }
          return 'Invalid request. Please try again.';
      }
    }
    if (status == 404) return 'Coupon not found.';
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Network timeout. Please check your connection and try again.';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    return 'Something went wrong. Please try again.';
  }

  String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message']?.toString() ??
          data['error']?.toString() ??
          data['detail']?.toString();
    }
    return null;
  }
}

final customerCouponRedemptionProvider =
    NotifierProvider<CustomerCouponRedemptionNotifier, CouponRedemptionState>(
      CustomerCouponRedemptionNotifier.new,
    );
