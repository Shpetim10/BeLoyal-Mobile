import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/data/repositories/customer_repository.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_detail_sheet.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_coupon_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

// Helper: validates eligibility then shows the confirmation dialog.
Future<void> _confirmAndRedeem(
  BuildContext context,
  WidgetRef ref,
  CustomerCoupon coupon,
) async {
  // Step 1 — pre-flight validate
  ValidateRedemptionDto? validation;
  String? networkError;
  try {
    validation = await ref
        .read(customerRepositoryProvider)
        .validateRedemption(coupon.couponId);
    if (!context.mounted) return;
    if (validation.canRedeem == false) {
      final reason = validation.reason?.isNotEmpty == true
          ? validation.reason!
          : 'This coupon is no longer available.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reason,
            style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      // Silently refresh so the card updates to its disabled state
      ref.read(customerDataProvider.notifier).refresh();
      return;
    }
  } catch (_) {
    networkError =
        'Could not verify eligibility. Please check your connection.';
  }

  if (!context.mounted) return;

  // Step 2 — show confirmation dialog (with balance info if available)
  final confirmed = await _CouponConfirmSheet.show(
    context,
    coupon,
    validation: validation,
    networkError: networkError,
  );
  if (confirmed == true && context.mounted) {
    ref
        .read(customerCouponRedemptionProvider.notifier)
        .redeemCoupon(couponId: coupon.couponId, couponTitle: coupon.title);
  }
}

class _CouponConfirmSheet {
  const _CouponConfirmSheet._();

  static Future<bool?> show(
    BuildContext context,
    CustomerCoupon coupon, {
    ValidateRedemptionDto? validation,
    String? networkError,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryDark, AppColors.primary],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Confirm Purchase',
                      style: AppTypography.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${coupon.title} • ${coupon.businessName}',
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Column(
                        children: [
                          // ── Cost ─────────────────────────────────────
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Cost',
                                style: AppTypography.dmSans(
                                  fontSize: 13,
                                  color: AppColors.textMutedDark,
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.stars_rounded,
                                    size: 15,
                                    color: AppColors.gold,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${coupon.pointCost} pts',
                                    style: AppTypography.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.gold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // ── Balance before → after ────────────────────
                          if (validation != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Balance',
                                  style: AppTypography.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      '${validation.customerBalance} pts',
                                      style: AppTypography.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textOnDark,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    const Icon(
                                      Icons.arrow_forward_rounded,
                                      size: 12,
                                      color: AppColors.textMutedDark,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      '${(validation.customerBalance - coupon.pointCost).clamp(0, validation.customerBalance)} pts',
                                      style: AppTypography.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          // ── Per-customer usage ────────────────────────
                          if (coupon.usageLimit != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Your usage',
                                  style: AppTypography.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                                Text(
                                  '${coupon.customerRedemptionCount} of ${coupon.usageLimit} allowed',
                                  style: AppTypography.dmSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textOnDark,
                                  ),
                                ),
                              ],
                            ),
                          ] else if (coupon.isOwned) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'You already own this coupon. Buying again adds another.',
                                    style: AppTypography.dmSans(
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // ── Network error warning ─────────────────────────
                    if (networkError != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off_rounded,
                              size: 13,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                networkError,
                                style: AppTypography.dmSans(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(false),
                            child: Container(
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.cardDark,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.glassBorder,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: AppTypography.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMutedDark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: networkError != null
                                ? null
                                : () => Navigator.of(context).pop(true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: networkError != null
                                    ? null
                                    : const LinearGradient(
                                        colors: [
                                          AppColors.primaryDark,
                                          AppColors.primary,
                                        ],
                                      ),
                                color: networkError != null
                                    ? AppColors.cardDark
                                    : null,
                                borderRadius: BorderRadius.circular(14),
                                border: networkError != null
                                    ? Border.all(color: AppColors.glassBorder)
                                    : null,
                                boxShadow: networkError != null
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: Text(
                                  'Confirm Buy',
                                  style: AppTypography.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: networkError != null
                                        ? AppColors.textMutedDark
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum CustomerCouponsTab { myCoupons, allCoupons }

class CustomerViewAllCouponsPage extends ConsumerStatefulWidget {
  const CustomerViewAllCouponsPage({
    super.key,
    this.initialFilter = 'all',
    this.initialTab = CustomerCouponsTab.myCoupons,
  });

  final String initialFilter;
  final CustomerCouponsTab initialTab;

  @override
  ConsumerState<CustomerViewAllCouponsPage> createState() =>
      _CustomerViewAllCouponsPageState();
}

class _CustomerViewAllCouponsPageState
    extends ConsumerState<CustomerViewAllCouponsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late String _filter;
  late CustomerCouponsTab _selectedTab;

  static const _filters = [
    ('all', 'All'),
    ('active', 'Active'),
    ('expiring', 'Expiring'),
    ('used', 'Used'),
    ('expired', 'Expired'),
  ];

  @override
  void initState() {
    super.initState();
    _filter = widget.initialFilter;
    _selectedTab = widget.initialTab;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CustomerCoupon> _filtered(List<CustomerCoupon> coupons) {
    return coupons.where((c) {
      if (_searchQuery.isNotEmpty &&
          !c.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !c.businessName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filter == 'all') return true;
      return c.status == _filter;
    }).toList();
  }

  IconData _typeIcon(String type) => couponTypeIcon(type);
  Color _statusColor(String status) => couponStatusColor(status);
  String _statusLabel(String status) => couponStatusLabel(status);

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponRedemptionState>(customerCouponRedemptionProvider, (
      _,
      next,
    ) {
      if (next is CouponRedemptionSuccess) {
        final remaining = next.result.remainingBalance;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon purchased! $remaining pts remaining',
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        ref.read(customerCouponRedemptionProvider.notifier).reset();
      } else if (next is CouponRedemptionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.message,
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        ref.read(customerCouponRedemptionProvider.notifier).reset();
      }
    });

    final customerData = ref.watch(customerDataProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: customerData.maybeWhen(
          data: (data) {
            final source = _selectedTab == CustomerCouponsTab.myCoupons
                ? data.myCoupons
                : data.allCoupons;
            final title = _selectedTab == CustomerCouponsTab.myCoupons
                ? 'My Coupons'
                : 'All Coupons';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOnDark,
                  ),
                ),
                Text(
                  '${source.length} coupons available',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            );
          },
          orElse: () => Text(
            'Coupons & Offers',
            style: AppTypography.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ),
      body: customerData.when(
        loading: () => const CustomerLoadingState(),
        error: (_, __) => CustomerErrorState(
          onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
        ),
        data: (data) {
          final myCoupons = data.myCoupons;
          final allCoupons = data.allCoupons;
          final source = _selectedTab == CustomerCouponsTab.myCoupons
              ? myCoupons
              : allCoupons;
          final expiring = source.where((c) => c.status == 'expiring').length;
          final coupons = _filtered(source);

          return Column(
            children: [
              if (expiring > 0)
                GestureDetector(
                  onTap: () => setState(() => _filter = 'expiring'),
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '$expiring coupon${expiring > 1 ? 's are' : ' is'} expiring soon. Tap to filter.',
                            style: AppTypography.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: AppColors.error,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: _CouponsTabSwitcher(
                  selectedTab: _selectedTab,
                  myCount: myCoupons.length,
                  allCount: allCoupons.length,
                  onChanged: (tab) => setState(() => _selectedTab = tab),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedTab == CustomerCouponsTab.myCoupons
                        ? 'Search my coupons...'
                        : 'Search all business coupons...',
                    hintStyle: AppTypography.dmSans(
                      fontSize: 14,
                      color: AppColors.textMutedDark,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMutedDark,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Icon(
                              Icons.clear_rounded,
                              color: AppColors.textMutedDark,
                              size: 18,
                            ),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.cardDark,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _filters.map((f) {
                    final isSelected = _filter == f.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _filter = f.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          f.$2,
                          style: AppTypography.dmSans(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textMutedDark,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.read(customerDataProvider.notifier).refresh(),
                  color: AppColors.primary,
                  backgroundColor: const Color(0xFF1A0535),
                  child: coupons.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: _EmptyCouponsState(
                                selectedTab: _selectedTab,
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: coupons.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) => _CouponListCard(
                            coupon: coupons[i],
                            typeIcon: _typeIcon(coupons[i].type),
                            statusColor: _statusColor(coupons[i].status),
                            statusLabel: _statusLabel(coupons[i].status),
                            onTap: () => CustomerCouponDetailSheet.show(
                              context,
                              coupons[i],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CouponsTabSwitcher extends StatelessWidget {
  const _CouponsTabSwitcher({
    required this.selectedTab,
    required this.myCount,
    required this.allCount,
    required this.onChanged,
  });

  final CustomerCouponsTab selectedTab;
  final int myCount;
  final int allCount;
  final ValueChanged<CustomerCouponsTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _CouponsTabButton(
              label: 'My Coupons',
              count: myCount,
              isSelected: selectedTab == CustomerCouponsTab.myCoupons,
              onTap: () => onChanged(CustomerCouponsTab.myCoupons),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CouponsTabButton(
              label: 'All Coupons',
              count: allCount,
              isSelected: selectedTab == CustomerCouponsTab.allCoupons,
              onTap: () => onChanged(CustomerCouponsTab.allCoupons),
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponsTabButton extends StatelessWidget {
  const _CouponsTabButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textMutedDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.18)
                    : AppColors.glassBorder,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTypography.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : AppColors.textMutedDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCouponsState extends StatelessWidget {
  const _EmptyCouponsState({required this.selectedTab});

  final CustomerCouponsTab selectedTab;

  @override
  Widget build(BuildContext context) {
    final message = selectedTab == CustomerCouponsTab.myCoupons
        ? 'No coupons found in your wallet.'
        : 'No business-wide coupons matched this filter.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 56,
            color: AppColors.textMutedDark.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.dmSans(
              fontSize: 14,
              color: AppColors.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponListCard extends ConsumerWidget {
  const _CouponListCard({
    required this.coupon,
    required this.typeIcon,
    required this.statusColor,
    required this.statusLabel,
    this.onTap,
  });

  final CustomerCoupon coupon;
  final IconData typeIcon;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final expiresAt = coupon.expiresAt != null
        ? DateFormat('MMM d').format(coupon.expiresAt!)
        : 'No expiry';
    final expiresIn = coupon.expiresIn ?? coupon.expiryLabel;
    final isPerLimitReached = coupon.isPerCustomerLimitReached;
    final isOverallLimitReached = coupon.isOverallLimitReached;
    final isLimitReached = coupon.isLimitReached;
    final redemptionState = ref.watch(customerCouponRedemptionProvider);
    final isClaimLoading = redemptionState is CouponRedemptionLoading;

    final borderColor = isLimitReached
        ? (isPerLimitReached ? AppColors.warning : AppColors.error).withValues(
            alpha: 0.35,
          )
        : coupon.status == 'expiring'
        ? AppColors.error.withValues(alpha: 0.3)
        : AppColors.glassBorder;

    // Don't grey the card when the customer can still buy more instances,
    // even if their current instance is marked as used.
    final cardOpacity = coupon.canBuyMore
        ? 1.0
        : (coupon.isUsed || coupon.status == 'expired')
        ? 0.55
        : (isLimitReached ? 0.7 : 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: cardOpacity,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // ── Left gradient side ───────────────────────────────
                      Container(
                        width: 76,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                (!coupon.canBuyMore &&
                                    (coupon.isUsed ||
                                        coupon.status == 'expired' ||
                                        isLimitReached))
                                ? [
                                    const Color(0xFF374151),
                                    const Color(0xFF6B7280),
                                  ]
                                : coupon.gradientColors,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLimitReached)
                              Icon(
                                isPerLimitReached
                                    ? Icons.person_off_rounded
                                    : Icons.inventory_2_rounded,
                                color: Colors.white.withValues(alpha: 0.8),
                                size: 22,
                              )
                            else ...[
                              Text(
                                coupon.discountDisplay,
                                style: AppTypography.outfit(
                                  fontSize: coupon.discountDisplay.length > 6
                                      ? 12
                                      : 15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Icon(
                                typeIcon,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ),
                      CustomPaint(
                        size: const Size(1, 110),
                        painter: _DashedPainter(),
                      ),
                      // ── Right content ─────────────────────────────────────
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      coupon.title,
                                      style: AppTypography.dmSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textOnDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isLimitReached) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            (isPerLimitReached
                                                    ? AppColors.warning
                                                    : AppColors.error)
                                                .withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isPerLimitReached
                                            ? 'My Limit'
                                            : 'Sold Out',
                                        style: AppTypography.dmSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isPerLimitReached
                                              ? AppColors.warning
                                              : AppColors.error,
                                        ),
                                      ),
                                    ),
                                  ] else ...[
                                    if (coupon.isFeatured) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.gold.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          'Featured',
                                          style: AppTypography.dmSans(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.gold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        statusLabel,
                                        style: AppTypography.dmSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              if (isLimitReached)
                                Text(
                                  coupon.limitReachedReason,
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    color:
                                        (isPerLimitReached
                                                ? AppColors.warning
                                                : AppColors.error)
                                            .withValues(alpha: 0.8),
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              else if (coupon.description.isNotEmpty)
                                Text(
                                  coupon.description,
                                  style: AppTypography.dmSans(
                                    fontSize: 11,
                                    color: AppColors.textMutedDark,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (coupon.status == 'expiring')
                                    Icon(
                                      Icons.local_fire_department_rounded,
                                      size: 11,
                                      color: AppColors.error,
                                    )
                                  else
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 11,
                                      color: AppColors.textMutedDark,
                                    ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '$expiresAt • $expiresIn',
                                      style: AppTypography.dmSans(
                                        fontSize: 11,
                                        fontWeight: coupon.status == 'expiring'
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: coupon.status == 'expiring'
                                            ? AppColors.error
                                            : AppColors.textMutedDark,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  CouponActionChipRow(
                                    coupon: coupon,
                                    isClaimLoading: isClaimLoading,
                                    onClaim: () =>
                                        _confirmAndRedeem(context, ref, coupon),
                                  ),
                                ],
                              ),
                              if (coupon.pointCost > 0) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.stars_rounded,
                                      size: 12,
                                      color: AppColors.gold,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${coupon.pointCost} pts',
                                      style: AppTypography.dmSans(
                                        fontSize: 11,
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (isPerLimitReached) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.warning.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${coupon.customerRedemptionCount}/${coupon.usageLimit} ✓',
                                          style: AppTypography.dmSans(
                                            fontSize: 10,
                                            color: AppColors.warning,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ] else if (isOverallLimitReached) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(
                                            alpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} sold',
                                          style: AppTypography.dmSans(
                                            fontSize: 10,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ] else if (coupon.usageLimit != null) ...[
                                      Text(
                                        '${coupon.customerRedemptionCount}/${coupon.usageLimit} bought',
                                        style: AppTypography.dmSans(
                                          fontSize: 10,
                                          color:
                                              coupon.customerRedemptionCount > 0
                                              ? AppColors.primary
                                              : AppColors.textMutedDark,
                                        ),
                                      ),
                                    ] else if (coupon.totalRedemptionLimit !=
                                        null) ...[
                                      Text(
                                        '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} sold',
                                        style: AppTypography.dmSans(
                                          fontSize: 10,
                                          color: AppColors.textMutedDark,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (coupon.termsAndConditions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                      child: Text(
                        '* ${coupon.termsAndConditions}',
                        style: AppTypography.dmSans(
                          fontSize: 10,
                          color: AppColors.textMutedDark.withValues(alpha: 0.6),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            // ── Diagonal "SOLD OUT" stamp for overall-limit-reached ──────────
            if (isOverallLimitReached && isActive)
              Positioned(
                top: 0,
                right: 0,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      'SOLD OUT',
                      style: AppTypography.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
            if (isPerLimitReached && !isOverallLimitReached && isActive)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                  child: Text(
                    'LIMIT HIT',
                    style: AppTypography.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.glassBorder
      ..strokeWidth = 1;
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
