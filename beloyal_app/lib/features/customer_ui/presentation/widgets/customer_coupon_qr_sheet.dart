import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';

class CustomerCouponQrSheet extends ConsumerStatefulWidget {
  const CustomerCouponQrSheet({super.key, required this.coupon});

  final CustomerCoupon coupon;

  static Future<void> show(BuildContext context, CustomerCoupon coupon) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => CustomerCouponQrSheet(coupon: coupon),
    ).then((_) {
      // Refresh coupon state when sheet closes so status reflects any staff scan
      if (context.mounted) {
        ProviderScope.containerOf(
          context,
        ).read(customerDataProvider.notifier).refresh();
      }
    });
  }

  @override
  ConsumerState<CustomerCouponQrSheet> createState() =>
      _CustomerCouponQrSheetState();
}

class _CustomerCouponQrSheetState extends ConsumerState<CustomerCouponQrSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  CustomerCoupon get _coupon => widget.coupon;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutBack));
    _animCtrl.forward();

    // Keep screen on while QR is displayed
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _isFreeProduct => _coupon.isFreeProduct;

  String get _instruction => _isFreeProduct
      ? 'Show this QR code to staff to redeem your free product.'
      : 'Show this QR code to staff during payment.\nYour discount will be applied before points are calculated.';

  Color get _accentColor =>
      _isFreeProduct ? AppColors.success : AppColors.accent;

  IconData get _typeIcon => switch (_coupon.type) {
    'FREE_PRODUCT' => Icons.card_giftcard_rounded,
    'PERCENTAGE_DISCOUNT' => Icons.percent_rounded,
    'FIXED_AMOUNT_DISCOUNT' => Icons.discount_rounded,
    _ => Icons.confirmation_number_rounded,
  };

  String get _typeLabel => switch (_coupon.type) {
    'FREE_PRODUCT' => 'Free Product',
    'PERCENTAGE_DISCOUNT' => 'Percentage Discount',
    'FIXED_AMOUNT_DISCOUNT' => 'Fixed Discount',
    _ => _coupon.type,
  };

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasQr = _coupon.qrCode?.isNotEmpty == true;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
          children: [
            // ── Handle ─────────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ─────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_typeIcon, size: 12, color: _accentColor),
                        const SizedBox(width: 5),
                        Text(
                          _typeLabel,
                          style: AppTypography.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _coupon.title,
                    style: AppTypography.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _coupon.businessName,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── QR Code ────────────────────────────────────────────────────
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Center(child: _buildQrPanel(hasQr)),
              ),
            ),
            const SizedBox(height: 20),
            // ── Instruction banner ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accentColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _isFreeProduct
                        ? Icons.qr_code_scanner_rounded
                        : Icons.point_of_sale_rounded,
                    size: 18,
                    color: _accentColor,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _instruction,
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        color: AppColors.textOnDark,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // ── Discount / free-product details ────────────────────────────
            _buildDetailsCard(),
            const SizedBox(height: 16),
            // ── Expiry ─────────────────────────────────────────────────────
            _buildExpiryRow(),
            const SizedBox(height: 24),
            // ── Close button ───────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Center(
                  child: Text(
                    'Done',
                    style: AppTypography.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrPanel(bool hasQr) {
    if (!hasQr) {
      return Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_rounded,
              size: 48,
              color: AppColors.textMutedDark,
            ),
            const SizedBox(height: 12),
            Text(
              'QR code unavailable.\nPlease show your coupon\ndetails to staff.',
              textAlign: TextAlign.center,
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.textMutedDark,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          QrImageView(
            data: _coupon.qrCode!,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _coupon.qrCode!.length > 16
                ? '${_coupon.qrCode!.substring(0, 8)}...${_coupon.qrCode!.substring(_coupon.qrCode!.length - 8)}'
                : _coupon.qrCode!,
            style: AppTypography.dmSans(
              fontSize: 10,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard() {
    final isFreeProduct = _coupon.isFreeProduct;
    final hasFreeProductInfo =
        _coupon.freeProductName?.isNotEmpty == true ||
        _coupon.freeProductVariant?.isNotEmpty == true ||
        _coupon.freeProductCategory?.isNotEmpty == true;

    if (!isFreeProduct && _coupon.discountValue <= 0 && !hasFreeProductInfo) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          if (!isFreeProduct && _coupon.discountValue > 0) ...[
            _DetailRow(
              icon: Icons.discount_rounded,
              label: 'Discount',
              value: _coupon.discountDisplay,
              valueColor: AppColors.success,
            ),
          ],
          if (!isFreeProduct &&
              _coupon.minimumOrderAmount != null &&
              _coupon.minimumOrderAmount! > 0) ...[
            const _Divider(),
            _DetailRow(
              icon: Icons.shopping_cart_outlined,
              label: 'Min. Order',
              value: 'L ${_coupon.minimumOrderAmount!.toStringAsFixed(0)}',
            ),
          ],
          if (!isFreeProduct &&
              _coupon.maximumDiscountAmount != null &&
              _coupon.maximumDiscountAmount! > 0) ...[
            const _Divider(),
            _DetailRow(
              icon: Icons.calculate_outlined,
              label: 'Max Discount',
              value: 'L ${_coupon.maximumDiscountAmount!.toStringAsFixed(0)}',
              valueColor: AppColors.success,
            ),
          ],
          if (isFreeProduct && hasFreeProductInfo) ...[
            if (_coupon.freeProductName?.isNotEmpty == true)
              _DetailRow(
                icon: Icons.restaurant_menu_rounded,
                label: 'Free Item',
                value: _coupon.freeProductName!,
                valueColor: AppColors.success,
              ),
            if (_coupon.freeProductVariant?.isNotEmpty == true) ...[
              const _Divider(),
              _DetailRow(
                icon: Icons.tune_rounded,
                label: 'Variant',
                value: _coupon.freeProductVariant!,
              ),
            ],
            if (_coupon.freeProductQuantity != null &&
                _coupon.freeProductQuantity! > 0) ...[
              const _Divider(),
              _DetailRow(
                icon: Icons.numbers_rounded,
                label: 'Quantity',
                value: '× ${_coupon.freeProductQuantity}',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExpiryRow() {
    final isExpired = _coupon.expiresAt.isBefore(DateTime.now());
    final daysLeft = _coupon.expiresAt.difference(DateTime.now()).inDays;
    final hoursLeft = _coupon.expiresAt.difference(DateTime.now()).inHours;
    final expiryFmt = DateFormat('MMM d, yyyy – h:mm a');

    final timeLabel = isExpired
        ? 'Expired ${(-daysLeft)}d ago'
        : hoursLeft < 24
        ? 'Expires in ${hoursLeft}h'
        : 'Expires in ${daysLeft}d';

    final expiryColor = isExpired
        ? AppColors.error
        : hoursLeft < 24
        ? AppColors.warning
        : AppColors.textMutedDark;

    return Row(
      children: [
        Icon(Icons.access_time_rounded, size: 14, color: expiryColor),
        const SizedBox(width: 6),
        Text(
          '${expiryFmt.format(_coupon.expiresAt)}  ($timeLabel)',
          style: AppTypography.dmSans(fontSize: 12, color: expiryColor),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMutedDark),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textOnDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.glassBorder,
      indent: 16,
      endIndent: 16,
    );
  }
}
