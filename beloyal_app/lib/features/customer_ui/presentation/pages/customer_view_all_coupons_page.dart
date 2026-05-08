import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/mock/customer_mock_data.dart';

class CustomerViewAllCouponsPage extends StatefulWidget {
  const CustomerViewAllCouponsPage({super.key, this.initialFilter = 'all'});
  final String initialFilter;

  @override
  State<CustomerViewAllCouponsPage> createState() => _CustomerViewAllCouponsPageState();
}

class _CustomerViewAllCouponsPageState extends State<CustomerViewAllCouponsPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  late String _filter;

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
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<MockCoupon> get _filtered {
    return CustomerMockData.coupons.where((c) {
      if (_searchQuery.isNotEmpty &&
          !c.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !c.businessName.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      if (_filter == 'all') return true;
      return c.status == _filter;
    }).toList();
  }

  IconData _typeIcon(String type) => switch (type) {
    'FREE_PRODUCT' => Icons.card_giftcard_rounded,
    'PERCENTAGE_DISCOUNT' => Icons.percent_rounded,
    'FIXED_AMOUNT_DISCOUNT' => Icons.discount_rounded,
    _ => Icons.confirmation_number_rounded,
  };

  Color _statusColor(String status) => switch (status) {
    'active' => AppColors.success,
    'expiring' => AppColors.error,
    'used' => AppColors.textMutedDark,
    'expired' => AppColors.textMutedDark,
    _ => AppColors.textMutedDark,
  };

  String _statusLabel(String status) => switch (status) {
    'active' => 'Active',
    'expiring' => 'Expiring',
    'used' => 'Used',
    'expired' => 'Expired',
    _ => status,
  };

  @override
  Widget build(BuildContext context) {
    final expiring = CustomerMockData.coupons.where((c) => c.status == 'expiring').length;
    final coupons = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Coupons', style: AppTypography.outfit(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textOnDark)),
            Text('${CustomerMockData.coupons.length} coupons total', style: AppTypography.dmSans(fontSize: 12, color: AppColors.textMutedDark)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Expiring banner
          if (expiring > 0)
            GestureDetector(
              onTap: () => setState(() => _filter = 'expiring'),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: AppColors.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$expiring coupon${expiring > 1 ? 's' : ''} expiring soon! Tap to view.',
                        style: AppTypography.dmSans(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.error),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.error, size: 14),
                  ],
                ),
              ),
            ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTypography.dmSans(fontSize: 14, color: AppColors.textOnDark),
              decoration: InputDecoration(
                hintText: 'Search coupons...',
                hintStyle: AppTypography.dmSans(fontSize: 14, color: AppColors.textMutedDark),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMutedDark, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                        child: const Icon(Icons.clear_rounded, color: AppColors.textMutedDark, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.cardDark,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.glassBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.glassBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              ),
            ),
          ),
          // Filter chips
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.cardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.glassBorder),
                    ),
                    child: Text(
                      f.$2,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textMutedDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Expanded(
            child: coupons.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.confirmation_number_outlined, size: 56, color: AppColors.textMutedDark.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No coupons found.', style: AppTypography.dmSans(fontSize: 14, color: AppColors.textMutedDark)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                    physics: const BouncingScrollPhysics(),
                    itemCount: coupons.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CouponListCard(
                      coupon: coupons[i],
                      typeIcon: _typeIcon(coupons[i].type),
                      statusColor: _statusColor(coupons[i].status),
                      statusLabel: _statusLabel(coupons[i].status),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CouponListCard extends StatelessWidget {
  const _CouponListCard({
    required this.coupon,
    required this.typeIcon,
    required this.statusColor,
    required this.statusLabel,
  });

  final MockCoupon coupon;
  final IconData typeIcon;
  final Color statusColor;
  final String statusLabel;

  @override
  Widget build(BuildContext context) {
    final isActive = coupon.status == 'active' || coupon.status == 'expiring';
    final hoursLeft = coupon.expiresAt.difference(DateTime.now()).inHours;
    final daysLeft = coupon.expiresAt.difference(DateTime.now()).inDays;
    final isExpired = coupon.expiresAt.isBefore(DateTime.now());
    final timeLabel = isExpired
        ? 'Expired ${(-daysLeft)}d ago'
        : hoursLeft < 24
            ? 'Expires in ${hoursLeft}h'
            : 'Expires in ${daysLeft}d';

    return Opacity(
      opacity: coupon.isUsed || coupon.status == 'expired' ? 0.55 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: coupon.status == 'expiring' ? AppColors.error.withValues(alpha: 0.3) : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            // Left strip
            Container(
              width: 76,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: coupon.isUsed || coupon.status == 'expired'
                      ? [const Color(0xFF374151), const Color(0xFF6B7280)]
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
                  Text(
                    coupon.discountDisplay,
                    style: AppTypography.outfit(
                      fontSize: coupon.discountDisplay.length > 6 ? 11 : 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Icon(typeIcon, color: Colors.white.withValues(alpha: 0.7), size: 16),
                ],
              ),
            ),
            // Dashed divider
            _DashedLine(),
            // Right content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(coupon.title, style: AppTypography.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textOnDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(statusLabel, style: AppTypography.dmSans(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(coupon.businessName, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 11, color: AppColors.textMutedDark),
                        const SizedBox(width: 4),
                        Text(timeLabel, style: AppTypography.dmSans(fontSize: 11, color: AppColors.textMutedDark)),
                        const Spacer(),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Use Now', style: AppTypography.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(1, 100),
      painter: _DashedPainter(),
    );
  }
}

class _DashedPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.glassBorder..strokeWidth = 1;
    const dH = 5.0, dS = 4.0;
    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(0, y + dH), paint);
      y += dH + dS;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
