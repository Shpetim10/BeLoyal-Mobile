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
    final homeDto = await repo.fetchHome();
    List<CustomerPromotionDto> myCouponDtos;
    bool walletLoadFailed = false;
    try {
      myCouponDtos = await repo.fetchMyCoupons();
    } catch (_) {
      myCouponDtos = const [];
      walletLoadFailed = true;
    }
    return CustomerDataSource.fromDto(
      homeDto,
      myCouponDtos: myCouponDtos,
      walletLoadFailed: walletLoadFailed,
    );
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

/// Maps a [CustomerPromotionDto] to a [CustomerCoupon] for detail surfaces.
/// [source] is an optional existing coupon to fall back to for gradient colors.
CustomerCoupon couponFromPromotionDto(
  CustomerPromotionDto dto, {
  CustomerCoupon? source,
}) {
  final expiresAt = dto.expiresAt;
  final expiresIn =
      dto.expiresIn ??
      (expiresAt != null ? _calculateExpiresIn(expiresAt) : null);
  final canonicalType = CustomerCouponType.canonical(dto.promotionType);
  final canonicalStatus = canonicalCouponStatus(
    dto.status,
    expiresAt: expiresAt,
  );

  return CustomerCoupon(
    couponId: dto.couponId,
    sourceId: dto.sourceId,
    businessId: dto.businessId,
    businessName: dto.businessName,
    title: dto.title,
    // Owned-instance endpoints (/customer/customer-coupons/{id}) may not echo
    // back template-level fields. Fall back to source for any that are missing.
    discountValue: dto.discountValue ?? source?.discountValue ?? 0,
    discountDisplay: dto.discountDisplay.isNotEmpty
        ? dto.discountDisplay
        : (source?.discountDisplay ?? dto.discountDisplay),
    status: canonicalStatus,
    expiresAt: expiresAt,
    pointCost: dto.pointCost != 0
        ? dto.pointCost
        : (source?.pointCost ?? dto.pointCost),
    gradientColors:
        source?.gradientColors ?? const [Color(0xFF1A0535), Color(0xFF9B5DE5)],
    type: canonicalType,
    isUsed: dto.isUsed,
    description: dto.description.isNotEmpty
        ? dto.description
        : (source?.description ?? dto.description),
    expiresIn: expiresIn,
    termsAndConditions: dto.termsAndConditions?.isNotEmpty == true
        ? dto.termsAndConditions!
        : (source?.termsAndConditions ?? dto.termsAndConditions ?? ''),
    usageLimit: dto.usageLimit ?? source?.usageLimit,
    usageCount: dto.usageCount,
    // customerRedemptionCount only increases; prefer the higher value so the
    // limit check stays correct even when the instance endpoint omits this field.
    customerRedemptionCount: dto.customerRedemptionCount > 0
        ? dto.customerRedemptionCount
        : (source?.customerRedemptionCount ?? dto.customerRedemptionCount),
    isHot: dto.isHot,
    // Once owned, a coupon cannot become un-owned from a fresh detail fetch.
    isOwned: dto.isOwned || (source?.isOwned ?? false),
    imageUrl: dto.imageUrl ?? source?.imageUrl,
    currency: dto.currency ?? source?.currency,
    isFeatured: dto.isFeatured,
    totalRedemptions: dto.totalRedemptions,
    totalRedemptionLimit:
        dto.totalRedemptionLimit ?? source?.totalRedemptionLimit,
    startDate: DateTime.tryParse(dto.startDate ?? ''),
    customerCouponId: dto.customerCouponId ?? source?.customerCouponId,
    minimumOrderAmount: dto.minimumOrderAmount ?? source?.minimumOrderAmount,
    maximumDiscountAmount:
        dto.maximumDiscountAmount ?? source?.maximumDiscountAmount,
    freeProductCategoryId:
        dto.freeProductCategoryId ?? source?.freeProductCategoryId,
    freeProductCategory: dto.freeProductCategory ?? source?.freeProductCategory,
    freeProductId: dto.freeProductId ?? source?.freeProductId,
    freeProductName: dto.freeProductName ?? source?.freeProductName,
    freeVariantId: dto.freeVariantId ?? source?.freeVariantId,
    freeProductVariant: dto.freeProductVariant ?? source?.freeProductVariant,
    freeProductQuantity: dto.freeProductQuantity ?? source?.freeProductQuantity,
    redeemedAt: dto.redeemedAt != null
        ? DateTime.tryParse(dto.redeemedAt!)
        : null,
    usedAt: dto.usedAt != null ? DateTime.tryParse(dto.usedAt!) : null,
    orderId: dto.orderId,
    qrCode: (dto.qrCode?.isNotEmpty == true) ? dto.qrCode : source?.qrCode,
    canRedeem: dto.canRedeem ?? source?.canRedeem,
    cannotRedeemReason: dto.cannotRedeemReason ?? source?.cannotRedeemReason,
    cannotRedeemCode: dto.cannotRedeemCode ?? source?.cannotRedeemCode,
    currencyCode: dto.currencyCode ?? source?.currencyCode,
    currencySymbol: dto.currencySymbol ?? source?.currencySymbol,
    canUse: dto.canUse ?? source?.canUse,
    cannotUseReason: dto.cannotUseReason ?? source?.cannotUseReason,
  );
}

final customerCouponDetailProvider = FutureProvider.autoDispose
    .family<CustomerCoupon, int>((ref, couponId) async {
      final repo = ref.read(customerRepositoryProvider);
      final dto = await repo.fetchCouponDetails(couponId);
      return couponFromPromotionDto(dto);
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
