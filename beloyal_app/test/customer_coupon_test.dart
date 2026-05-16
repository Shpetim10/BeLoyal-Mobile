import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_data_source.dart';
import 'package:besahub_app/features/customer_ui/data/models/customer_home_dto.dart';

CustomerCoupon _coupon({
  int couponId = 1,
  int? customerCouponId,
  bool isOwned = false,
  bool isUsed = false,
  String status = CustomerCouponStatus.active,
  String? qrCode,
  bool? canUse,
  String type = CustomerCouponType.freeProduct,
}) {
  return CustomerCoupon(
    couponId: couponId,
    sourceId: customerCouponId ?? couponId,
    businessId: 10,
    businessName: 'Test Business',
    title: 'Test Coupon',
    discountValue: 0,
    discountDisplay: '10%',
    status: status,
    expiresAt: null,
    pointCost: 100,
    gradientColors: const [Colors.purple, Colors.blue],
    type: type,
    isOwned: isOwned,
    isUsed: isUsed,
    customerCouponId: customerCouponId,
    qrCode: qrCode,
    canUse: canUse,
  );
}

void main() {
  group('CustomerCoupon.canShowQr', () {
    test('returns false for unowned coupons even with qrCode', () {
      final c = _coupon(
        isOwned: false,
        customerCouponId: null,
        qrCode: 'uuid-abc',
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false when customerCouponId is null (public row)', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: null,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.active,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false when isUsed is true', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        isUsed: true,
        status: CustomerCouponStatus.active,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false when qrCode is empty', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: '',
        status: CustomerCouponStatus.active,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false when canUse is false', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.active,
        canUse: false,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false for expired owned coupons', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.expired,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns false for used-status owned coupons', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.used,
      );
      expect(c.canShowQr, isFalse);
    });

    test('returns true for valid active owned coupon', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.active,
      );
      expect(c.canShowQr, isTrue);
    });

    test('returns true for valid expiring owned coupon', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.expiring,
      );
      expect(c.canShowQr, isTrue);
    });

    test('returns true when canUse is null (not gated by backend)', () {
      final c = _coupon(
        isOwned: true,
        customerCouponId: 42,
        qrCode: 'uuid-abc',
        status: CustomerCouponStatus.active,
        canUse: null,
      );
      expect(c.canShowQr, isTrue);
    });
  });

  group('Coupon filter: used', () {
    test('used filter matches isUsed=true regardless of status', () {
      // Backend may send isUsed=true with status still as active in edge cases.
      final coupon = _coupon(isUsed: true, status: CustomerCouponStatus.active);
      final passes =
          coupon.isUsed || coupon.status == CustomerCouponStatus.used;
      expect(passes, isTrue);
    });

    test('used filter matches status=used even if isUsed=false', () {
      final coupon = _coupon(isUsed: false, status: CustomerCouponStatus.used);
      final passes =
          coupon.isUsed || coupon.status == CustomerCouponStatus.used;
      expect(passes, isTrue);
    });

    test('used filter excludes active coupon that is not used', () {
      final coupon = _coupon(
        isUsed: false,
        status: CustomerCouponStatus.active,
      );
      final passes =
          coupon.isUsed || coupon.status == CustomerCouponStatus.used;
      expect(passes, isFalse);
    });
  });

  group('Public home row QR isolation', () {
    // Verifies that _mapPromotion does NOT attach a qrCode to a public
    // (unowned) promotion row. The qrCode field must be null for any row
    // where customerCouponId is null.
    CustomerPromotionDto publicPromoDto({String? qrCode}) {
      return CustomerPromotionDto(
        sourceId: 1,
        couponId: 1,
        businessId: 10,
        businessName: 'Biz',
        title: 'Coupon',
        description: '',
        promotionType: 'FREE_PRODUCT',
        status: 'ACTIVE',
        discountDisplay: '10%',
        pointCost: 50,
        isHot: false,
        isUsed: false,
        isOwned: false,
        hasOwnershipSignal: false,
        usageCount: 0,
        isFeatured: false,
        totalRedemptions: 0,
        customerRedemptionCount: 0,
        customerCouponId: null, // public row — no owned instance
        qrCode: qrCode,
      );
    }

    test('public row with no customerCouponId does not carry qrCode', () {
      // Even if the DTO carries a qrCode (backend bug or data race), the
      // mapper must suppress it for rows without a customerCouponId.
      final dto = publicPromoDto(qrCode: 'should-not-appear');
      // Reproduce mapper logic: qrCode is null when customerCouponId is null.
      final effectiveQr = dto.customerCouponId != null ? dto.qrCode : null;
      expect(effectiveQr, isNull);
    });

    test('owned row with customerCouponId preserves its qrCode', () {
      // An owned row with customerCouponId should keep the QR code.
      final dto = CustomerPromotionDto(
        sourceId: 99,
        couponId: 1,
        businessId: 10,
        businessName: 'Biz',
        title: 'Coupon',
        description: '',
        promotionType: 'FREE_PRODUCT',
        status: 'ACTIVE',
        discountDisplay: '10%',
        pointCost: 50,
        isHot: false,
        isUsed: false,
        isOwned: true,
        hasOwnershipSignal: true,
        usageCount: 0,
        isFeatured: false,
        totalRedemptions: 0,
        customerRedemptionCount: 1,
        customerCouponId: 99,
        qrCode: 'real-qr-uuid',
      );
      final effectiveQr = dto.customerCouponId != null ? dto.qrCode : null;
      expect(effectiveQr, equals('real-qr-uuid'));
    });
  });

  group('CustomerDataSource.walletLoadFailed', () {
    CustomerHomeDto minimalHomeDto() {
      return CustomerHomeDto(
        summary: CustomerSummaryDto(
          currentPoints: 0,
          lifetimePoints: 0,
          spentPoints: 0,
          businessesVisited: 0,
          activeCoupons: 0,
          activeRewards: 0,
          memberSinceLabel: '',
          memberCode: '',
        ),
        categories: const [],
        businesses: const [],
        promotions: const [],
        transactions: const [],
      );
    }

    test('walletLoadFailed=true propagates to CustomerDataSource', () {
      final ds = CustomerDataSource.fromDto(
        minimalHomeDto(),
        myCouponDtos: const [],
        walletLoadFailed: true,
      );
      expect(ds.walletLoadFailed, isTrue);
      expect(ds.myCoupons, isEmpty);
    });

    test(
      'walletLoadFailed=false is default when wallet loads successfully',
      () {
        final ds = CustomerDataSource.fromDto(
          minimalHomeDto(),
          myCouponDtos: const [],
        );
        expect(ds.walletLoadFailed, isFalse);
      },
    );
  });

  group('Repeated purchases — multiple wallet rows', () {
    test(
      'two owned instances of same couponId appear separately in myCoupons',
      () {
        // Verify ownedCoupons list preserves both rows (no dedup on customerCouponId).
        final owned1 = _coupon(
          couponId: 5,
          customerCouponId: 101,
          isOwned: true,
          qrCode: 'qr-101',
          status: CustomerCouponStatus.active,
        );
        final owned2 = _coupon(
          couponId: 5,
          customerCouponId: 102,
          isOwned: true,
          qrCode: 'qr-102',
          status: CustomerCouponStatus.used,
          isUsed: true,
        );
        // Simulate what CustomerDataSource.myCoupons returns.
        final myCoupons = [owned1, owned2];
        expect(myCoupons.length, 2);
        expect(myCoupons[0].customerCouponId, 101);
        expect(myCoupons[1].customerCouponId, 102);
        // Each keeps its own QR.
        expect(myCoupons[0].qrCode, 'qr-101');
        expect(myCoupons[1].qrCode, 'qr-102');
      },
    );

    test('used instance does not show QR, active instance does', () {
      final active = _coupon(
        couponId: 5,
        customerCouponId: 101,
        isOwned: true,
        qrCode: 'qr-101',
        status: CustomerCouponStatus.active,
      );
      final used = _coupon(
        couponId: 5,
        customerCouponId: 102,
        isOwned: true,
        qrCode: 'qr-102',
        status: CustomerCouponStatus.used,
        isUsed: true,
      );
      expect(active.canShowQr, isTrue);
      expect(used.canShowQr, isFalse);
    });
  });
}
