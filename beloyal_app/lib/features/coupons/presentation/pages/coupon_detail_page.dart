import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../features/auth/domain/models/auth_user.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../data/coupon_repository.dart';
import '../../data/models/coupon_detail.dart';
import '../../data/models/coupon_enums.dart';
import '../widgets/coupon_update_sheet.dart';
import '../widgets/coupon_status_chip.dart';

final couponDetailProvider = FutureProvider.autoDispose
    .family<CouponDetail, ({int businessId, int couponId})>((ref, args) {
      return ref
          .watch(couponRepositoryProvider)
          .getCoupon(businessId: args.businessId, couponId: args.couponId);
    });

class CouponDetailPage extends ConsumerWidget {
  const CouponDetailPage({
    super.key,
    required this.businessId,
    required this.couponId,
    this.inBottomSheet = false,
  });

  final int businessId;
  final int couponId;
  final bool inBottomSheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponAsync = ref.watch(
      couponDetailProvider((businessId: businessId, couponId: couponId)),
    );
    final session = ref.read(sessionControllerProvider);
    final isAdmin = session?.activeRole == UserRole.businessAdmin;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: Icon(
            inBottomSheet
                ? Icons.close_rounded
                : Icons.arrow_back_ios_new_rounded,
            color: AppColors.textOnDark,
            size: inBottomSheet ? 24 : 20,
          ),
          onPressed: () => inBottomSheet
              ? Navigator.of(context).pop()
              : context.go('/business/$businessId/coupons'),
        ),
        title: const Text(
          'Coupon Details',
          style: TextStyle(color: AppColors.textOnDark),
        ),
      ),
      bottomNavigationBar: couponAsync.whenOrNull(
        data: (coupon) => isAdmin
            ? _ActionBar(
                coupon: coupon,
                onChanged: () => ref.invalidate(
                  couponDetailProvider((
                    businessId: businessId,
                    couponId: couponId,
                  )),
                ),
              )
            : null,
      ),
      body: couponAsync.when(
        data: (coupon) => RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(
              couponDetailProvider((
                businessId: businessId,
                couponId: couponId,
              )),
            );
            await ref.read(
              couponDetailProvider((
                businessId: businessId,
                couponId: couponId,
              )).future,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              _CouponHero(coupon: coupon),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Overview',
                child: Column(
                  children: [
                    _DetailRow('Type', coupon.type.displayName),
                    _DetailRow('Points Cost', '${coupon.pointsCost} pts'),
                    _DetailRow('Visibility', coupon.visibility.displayName),
                    _DetailRow('Status', coupon.status.displayName),
                    _DetailRow(
                      'Validity',
                      '${_formatDate(coupon.startDate)} - ${_formatDate(coupon.endDate)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Limits & Usage',
                child: Column(
                  children: [
                    _DetailRow(
                      'Total Redemptions',
                      '${coupon.totalRedemptions}',
                    ),
                    _DetailRow(
                      'Total Redemption Limit',
                      coupon.totalRedemptionLimit?.toString() ?? 'Unlimited',
                    ),
                    _DetailRow(
                      'Per-Customer Limit',
                      coupon.perCustomerRedemptionLimit?.toString() ??
                          'Unlimited',
                    ),
                    _DetailRow('Featured', coupon.isFeatured ? 'Yes' : 'No'),
                    _DetailRow(
                      'Sort Order',
                      coupon.sortOrder?.toString() ?? 'Default',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (coupon.type == CouponType.freeProduct &&
                  coupon.freeProductDetails != null)
                _SectionCard(
                  title: 'Free Product Reward',
                  child: Column(
                    children: [
                      _DetailRow(
                        'Category',
                        coupon.freeProductDetails!.categoryName,
                      ),
                      _DetailRow(
                        'Product',
                        coupon.freeProductDetails!.productName,
                      ),
                      _DetailRow(
                        'Variant',
                        coupon.freeProductDetails!.variantName ?? 'No variant',
                      ),
                      _DetailRow(
                        'Quantity',
                        '${coupon.freeProductDetails!.quantity}',
                      ),
                    ],
                  ),
                ),
              if (coupon.discountDetails != null)
                _SectionCard(
                  title: 'Discount Configuration',
                  child: Column(
                    children: [
                      if (coupon.discountDetails!.discountPercentage != null)
                        _DetailRow(
                          'Discount Percentage',
                          '${coupon.discountDetails!.discountPercentage!.toStringAsFixed(0)}%',
                        ),
                      if (coupon.discountDetails!.discountAmount != null)
                        _DetailRow(
                          'Discount Amount',
                          _formatMoney(
                            coupon.discountDetails!.discountAmount!,
                            coupon.currency,
                          ),
                        ),
                      _DetailRow(
                        'Minimum Order Amount',
                        coupon.discountDetails!.minimumOrderAmount != null
                            ? _formatMoney(
                                coupon.discountDetails!.minimumOrderAmount!,
                                coupon.currency,
                              )
                            : 'None',
                      ),
                      _DetailRow(
                        'Maximum Discount Amount',
                        coupon.discountDetails!.maximumDiscountAmount != null
                            ? _formatMoney(
                                coupon.discountDetails!.maximumDiscountAmount!,
                                coupon.currency,
                              )
                            : 'None',
                      ),
                    ],
                  ),
                ),
              if ((coupon.description ?? '').trim().isNotEmpty ||
                  (coupon.termsAndConditions ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Copy',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((coupon.description ?? '').trim().isNotEmpty) ...[
                        const Text(
                          'Description',
                          style: TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          coupon.description!,
                          style: const TextStyle(
                            color: AppColors.textSubDark,
                            height: 1.5,
                          ),
                        ),
                      ],
                      if ((coupon.termsAndConditions ?? '')
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            color: AppColors.textMutedDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          coupon.termsAndConditions!,
                          style: const TextStyle(
                            color: AppColors.textSubDark,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        loading: () => const Center(
          child: const BesaLoader(),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 42,
                ),
                const SizedBox(height: 12),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSubDark),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(
                    couponDetailProvider((
                      businessId: businessId,
                      couponId: couponId,
                    )),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String _formatMoney(double value, CouponCurrency currency) {
    final fixed = value % 1 == 0
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    return '${currency.symbol} $fixed'.trim();
  }
}

class _CouponHero extends StatelessWidget {
  const _CouponHero({required this.coupon});

  final CouponDetail coupon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: coupon.imageUrl != null && coupon.imageUrl!.isNotEmpty
                ? Image.network(
                    coupon.imageUrl!,
                    height: 190,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _HeroPlaceholder(coupon: coupon),
                  )
                : _HeroPlaceholder(coupon: coupon),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    CouponTypeBadge(type: coupon.type),
                    CouponStatusChip(status: coupon.status),
                    _SmallChip(
                      icon: coupon.visibility.icon,
                      label: coupon.visibility.displayName,
                      color: coupon.visibility.color,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  coupon.title,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  (coupon.description ?? '').trim().isEmpty
                      ? 'No description provided.'
                      : coupon.description!,
                  style: TextStyle(
                    color: (coupon.description ?? '').trim().isEmpty
                        ? AppColors.textMuted
                        : AppColors.textSubDark,
                    fontStyle: (coupon.description ?? '').trim().isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPlaceholder extends StatelessWidget {
  const _HeroPlaceholder({required this.coupon});

  final CouponDetail coupon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      width: double.infinity,
      color: AppColors.elevDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(coupon.type.icon, size: 42, color: coupon.type.color),
          const SizedBox(height: 8),
          Text(
            coupon.type.displayName,
            style: const TextStyle(color: AppColors.textMutedDark),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({required this.coupon, required this.onChanged});

  final CouponDetail coupon;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transitions = coupon.status.allowedTransitions;
    final repo = ref.read(couponRepositoryProvider);
    final nextVisibility = coupon.visibility == CouponVisibility.public
        ? CouponVisibility.hidden
        : CouponVisibility.public;
    final visibilityActionLabel = nextVisibility == CouponVisibility.hidden
        ? 'Hide'
        : 'Show';

    Future<void> runAction(
      Future<void> Function() action,
      String success,
    ) async {
      try {
        await action();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        onChanged();
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    final actions = <_PanelAction>[
      if (transitions.contains(CouponStatus.active))
        _PanelAction(
          icon: Icons.play_circle_outline_rounded,
          label: 'Activate',
          color: AppColors.success,
          onTap: () => runAction(
            () => repo.changeCouponStatus(
              businessId: coupon.businessId,
              couponId: coupon.id,
              status: CouponStatus.active,
            ),
            'Coupon activated.',
          ),
        ),
      if (transitions.contains(CouponStatus.paused))
        _PanelAction(
          icon: Icons.pause_circle_outline_rounded,
          label: 'Pause',
          color: AppColors.warning,
          onTap: () => runAction(
            () => repo.changeCouponStatus(
              businessId: coupon.businessId,
              couponId: coupon.id,
              status: CouponStatus.paused,
            ),
            'Coupon paused.',
          ),
        ),
      if (transitions.contains(CouponStatus.draft))
        _PanelAction(
          icon: Icons.restart_alt_rounded,
          label: 'Draft',
          color: AppColors.info,
          onTap: () => runAction(
            () => repo.changeCouponStatus(
              businessId: coupon.businessId,
              couponId: coupon.id,
              status: CouponStatus.draft,
            ),
            'Coupon restored to draft.',
          ),
        ),
      if (transitions.contains(CouponStatus.archived))
        _PanelAction(
          icon: Icons.archive_outlined,
          label: 'Archive',
          color: AppColors.textMutedDark,
          onTap: () => runAction(
            () => repo.archiveCoupon(
              businessId: coupon.businessId,
              couponId: coupon.id,
            ),
            'Coupon archived.',
          ),
        ),
      _PanelAction(
        icon: nextVisibility == CouponVisibility.hidden
            ? Icons.visibility_off_outlined
            : Icons.visibility_outlined,
        label: visibilityActionLabel,
        color: nextVisibility == CouponVisibility.hidden
            ? AppColors.warning
            : AppColors.success,
        onTap: () => runAction(
          () => repo.updateCoupon(
            businessId: coupon.businessId,
            couponId: coupon.id,
            updates: {'visibility': nextVisibility.backendValue},
          ),
          nextVisibility == CouponVisibility.hidden
              ? 'Coupon hidden.'
              : 'Coupon is visible again.',
        ),
      ),
      _PanelAction(
        icon: Icons.edit_rounded,
        label: 'Update',
        color: AppColors.primary,
        onTap: () async {
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => FractionallySizedBox(
              heightFactor: 0.92,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(24)),
                child: CouponUpdateSheet(
                  businessId: coupon.businessId,
                  coupon: coupon,
                  onUpdated: onChanged,
                ),
              ),
            ),
          );
        },
      ),
      _PanelAction(
        icon: Icons.delete_outline_rounded,
        label: 'Delete',
        color: AppColors.error,
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.cardDark,
              title: const Text(
                'Move to Trash',
                style: TextStyle(color: AppColors.textOnDark),
              ),
              content: const Text(
                'Move this coupon to trash? You can restore it later from the Trash section.',
                style: TextStyle(color: AppColors.textSubDark),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.textMutedDark),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Move to Trash',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed != true) return;

          try {
            await repo.deleteCoupon(
              businessId: coupon.businessId,
              couponId: coupon.id,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Coupon moved to trash'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'View Trash',
                  onPressed: () => context.go('/business/${coupon.businessId}/coupons/trash'),
                ),
              ),
            );
            if (context.mounted) context.go('/business/${coupon.businessId}/coupons');
          } catch (error) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error.toString().replaceFirst('Exception: ', '')),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        border: Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _ActionIconButton(
                  icon: action.icon,
                  label: action.label,
                  color: action.color,
                  onTap: action.onTap,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelAction {
  const _PanelAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}
