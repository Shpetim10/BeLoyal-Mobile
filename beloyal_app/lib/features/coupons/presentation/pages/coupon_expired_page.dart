import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import '../controllers/coupon_expired_controller.dart';
import 'coupon_detail_page.dart';
import '../widgets/coupon_status_chip.dart';

class CouponExpiredPage extends ConsumerStatefulWidget {
  const CouponExpiredPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponExpiredPage> createState() => _CouponExpiredPageState();
}

class _CouponExpiredPageState extends ConsumerState<CouponExpiredPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchVisible = false;

  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFBBF24);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(couponExpiredControllerProvider.notifier)
          .fetchCoupons(widget.businessId);
    });
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    final ctrl = ref.read(couponExpiredControllerProvider.notifier);
    final state = ref.read(couponExpiredControllerProvider);
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      ctrl.fetchCoupons(widget.businessId, reset: false);
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(couponExpiredControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _onSearchChanged(String query) {
    ref.read(couponExpiredControllerProvider.notifier).updateSearch(query);
    ref
        .read(couponExpiredControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  Future<void> _showDetailSheet(CouponSummary coupon) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.92,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: CouponDetailPage(
            businessId: widget.businessId,
            couponId: coupon.id,
            inBottomSheet: true,
          ),
        ),
      ),
    );
    if (!mounted) return;
    ref
        .read(couponExpiredControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponExpiredState>(couponExpiredControllerProvider,
        (prev, next) {
      if (next.actionError != null && next.actionError != prev?.actionError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.actionError!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    final state = ref.watch(couponExpiredControllerProvider);
    final ctrl = ref.read(couponExpiredControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_amber, Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_off_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Expired',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Coupons',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchVisible ? Icons.search_off : Icons.search,
              color: AppColors.textOnDark,
            ),
            onPressed: () =>
                setState(() => _isSearchVisible = !_isSearchVisible),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppColors.textOnDark),
            onPressed: () => _showTypeFilterSheet(context, state, ctrl),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _amber.withValues(alpha: 0.12),
                  const Color(0xFFEF4444).withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _amber.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_off_outlined, color: _amberLight, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'These coupons have passed their end date. Revive them to extend availability for customers.',
                    style: TextStyle(
                      color: Color(0xFFFDE68A),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: _isSearchVisible
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(color: AppColors.textOnDark),
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search expired coupons...',
                        hintStyle:
                            const TextStyle(color: AppColors.textMutedDark),
                        prefixIcon: const Icon(Icons.search,
                            color: AppColors.textMutedDark),
                        filled: true,
                        fillColor: AppColors.elevDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Type filter chip
          if (state.typeFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Wrap(
                children: [
                  Chip(
                    label: Text(state.typeFilter!.shortLabel),
                    labelStyle:
                        TextStyle(color: state.typeFilter!.color, fontSize: 12),
                    backgroundColor:
                        state.typeFilter!.color.withValues(alpha: 0.15),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () {
                      ctrl.setTypeFilter(null);
                      ctrl.fetchCoupons(widget.businessId);
                    },
                  ),
                ],
              ),
            ),

          // Sort bar
          _ExpiredSortBar(
              state: state, ctrl: ctrl, businessId: widget.businessId),

          // List
          Expanded(
            child: state.isLoading && state.coupons.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _amber))
                : state.coupons.isEmpty
                    ? const _ExpiredEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: _amber,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.only(bottom: 40, top: 8),
                          itemCount: state.coupons.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.coupons.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: _amber),
                                ),
                              );
                            }
                            final coupon = state.coupons[index];
                            return _ExpiredCouponCard(
                              coupon: coupon,
                              onTap: () => _showDetailSheet(coupon),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _showReviveDatePicker(
    CouponSummary coupon,
    CouponExpiredController ctrl,
  ) async {
    final now = DateTime.now();
    DateTime? pickedStart;
    DateTime? pickedEnd;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            final dateLabel = DateFormat('MMM d, yyyy');
            return AlertDialog(
              backgroundColor: AppColors.cardDark,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: _amber, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Revive Coupon',
                    style: TextStyle(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set new start and end dates for "${coupon.title}".',
                    style: const TextStyle(
                        color: AppColors.textSubDark, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _DatePickerRow(
                    label: 'Start Date',
                    value: pickedStart,
                    placeholder: 'Select start date',
                    accentColor: _amber,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 5),
                        builder: (_, child) =>
                            _datePickerTheme(context, child),
                      );
                      if (picked != null) {
                        setDlgState(() => pickedStart = picked);
                        if (pickedEnd != null &&
                            !pickedEnd!.isAfter(picked)) {
                          setDlgState(() => pickedEnd = null);
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _DatePickerRow(
                    label: 'End Date',
                    value: pickedEnd,
                    placeholder: 'Select end date',
                    accentColor: _amber,
                    onTap: () async {
                      final firstDate =
                          pickedStart?.add(const Duration(days: 1)) ??
                              now.add(const Duration(days: 1));
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: firstDate,
                        firstDate: firstDate,
                        lastDate: DateTime(now.year + 5),
                        builder: (_, child) =>
                            _datePickerTheme(context, child),
                      );
                      if (picked != null) {
                        setDlgState(() => pickedEnd = picked);
                      }
                    },
                  ),
                  if (pickedStart != null && pickedEnd != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _amber.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 14,
                                color: _amber),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${dateLabel.format(pickedStart!)} → ${dateLabel.format(pickedEnd!)}',
                                style: const TextStyle(
                                    color: _amberLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        pickedStart != null && pickedEnd != null
                            ? _amber
                            : AppColors.textMutedDark,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: pickedStart != null && pickedEnd != null
                      ? () {
                          Navigator.pop(dialogCtx);
                          ctrl.revive(
                            businessId: widget.businessId,
                            couponId: coupon.id,
                            startDate: pickedStart!,
                            endDate: pickedEnd!,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.bolt_rounded, size: 16),
                  label: const Text('Revive',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _datePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _amber,
          onPrimary: Colors.black,
          surface: Color(0xFF1E2A3A),
          onSurface: AppColors.textOnDark,
        ),
      ),
      child: child!,
    );
  }

  void _confirmDelete(
    CouponSummary coupon,
    CouponExpiredController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded,
                color: AppColors.error, size: 22),
            SizedBox(width: 10),
            Text('Delete Coupon',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Delete "${coupon.title}"? It will be moved to trash.',
          style: const TextStyle(color: AppColors.textSubDark, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteCoupon(
                  businessId: widget.businessId, couponId: coupon.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTypeFilterSheet(
    BuildContext context,
    CouponExpiredState state,
    CouponExpiredController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Filter by Type',
                      style: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (state.typeFilter != null)
                    TextButton(
                      onPressed: () {
                        ctrl.setTypeFilter(null);
                        ctrl.fetchCoupons(widget.businessId);
                        Navigator.pop(context);
                      },
                      child: const Text('Clear'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CouponType.values.map((t) {
                  final isSelected = state.typeFilter == t;
                  return GestureDetector(
                    onTap: () {
                      ctrl.setTypeFilter(isSelected ? null : t);
                      ctrl.fetchCoupons(widget.businessId);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.color.withValues(alpha: 0.2)
                            : AppColors.elevDark,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? t.color.withValues(alpha: 0.6)
                              : AppColors.glassBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(t.icon,
                              size: 14,
                              color: isSelected
                                  ? t.color
                                  : AppColors.textSubDark),
                          const SizedBox(width: 6),
                          Text(t.shortLabel,
                              style: TextStyle(
                                  color: isSelected
                                      ? t.color
                                      : AppColors.textSubDark,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Bottom Sheet ───────────────────────────────────────────────────────

class _ExpiredDetailSheet extends StatelessWidget {
  const _ExpiredDetailSheet({
    required this.coupon,
    required this.onRevive,
    required this.onUpdate,
    required this.onDelete,
  });

  final CouponSummary coupon;
  final VoidCallback onRevive;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final daysExpired = DateTime.now().difference(coupon.endDate).inDays;

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Image
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    coupon.imageUrl != null
                        ? Image.network(
                            coupon.imageUrl!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.45),
                            colorBlendMode: BlendMode.darken,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_off_rounded,
                                size: 11, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              daysExpired == 0
                                  ? 'Expired today'
                                  : '${daysExpired}d ago',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CouponTypeBadge(type: coupon.type, small: true),
                  const SizedBox(height: 8),
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.monetization_on_outlined,
                        label: '${coupon.pointsCost} pts',
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      _InfoChip(
                        icon: Icons.people_outline_rounded,
                        label: '${coupon.totalRedemptions} used',
                        color: AppColors.textSubDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.event_busy_outlined,
                          size: 13, color: _amberLight),
                      const SizedBox(width: 6),
                      Text(
                        'Ended ${dateFormat.format(coupon.endDate)}',
                        style: const TextStyle(
                            color: _amberLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Divider(color: AppColors.glassBorder, height: 1),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _amber,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onRevive,
                      icon: const Icon(Icons.bolt_rounded, size: 18),
                      label: const Text('Revive Coupon',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                                color: AppColors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: onUpdate,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Update',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                                color: AppColors.error.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 16),
                          label: const Text('Delete',
                              style: TextStyle(fontWeight: FontWeight.w600)),
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
    );
  }

  Widget _buildPlaceholder() => Container(
        height: 160,
        width: double.infinity,
        color: _amber.withValues(alpha: 0.08),
        child: Icon(coupon.type.icon,
            size: 48, color: _amber.withValues(alpha: 0.3)),
      );
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Date picker row ───────────────────────────────────────────────────────────

class _DatePickerRow extends StatelessWidget {
  const _DatePickerRow({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.accentColor,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final String placeholder;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSubDark,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.elevDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: value != null
                    ? accentColor.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    size: 16,
                    color: value != null
                        ? accentColor
                        : AppColors.textMutedDark),
                const SizedBox(width: 10),
                Text(
                  value != null ? fmt.format(value!) : placeholder,
                  style: TextStyle(
                    color: value != null
                        ? AppColors.textOnDark
                        : AppColors.textMutedDark,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.edit_calendar_rounded,
                    size: 14, color: AppColors.textMutedDark),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Sort bar ──────────────────────────────────────────────────────────────────

class _ExpiredSortBar extends StatelessWidget {
  const _ExpiredSortBar({
    required this.state,
    required this.ctrl,
    required this.businessId,
  });

  final CouponExpiredState state;
  final CouponExpiredController ctrl;
  final int businessId;

  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final entry in const {
            'endDate': 'Expired Date',
            'pointsCost': 'Points',
            'title': 'Name',
          }.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (state.sortBy == entry.key) {
                    ctrl.toggleSortDirection();
                  } else {
                    ctrl.setSortBy(entry.key);
                  }
                  ctrl.fetchCoupons(businessId);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: state.sortBy == entry.key
                        ? _amber.withValues(alpha: 0.2)
                        : AppColors.elevDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.sortBy == entry.key
                          ? _amber.withValues(alpha: 0.5)
                          : AppColors.glassBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value,
                        style: TextStyle(
                          color: state.sortBy == entry.key
                              ? _amberLight
                              : AppColors.textSubDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (state.sortBy == entry.key) ...[
                        const SizedBox(width: 4),
                        Icon(
                          state.sortDirection == 'DESC'
                              ? Icons.arrow_downward
                              : Icons.arrow_upward,
                          size: 12,
                          color: _amberLight,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _ExpiredCouponCard extends StatelessWidget {
  const _ExpiredCouponCard({required this.coupon, required this.onTap});

  final CouponSummary coupon;
  final VoidCallback onTap;

  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final daysExpired = DateTime.now().difference(coupon.endDate).inDays;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _amber.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  coupon.imageUrl != null
                      ? Image.network(
                          coupon.imageUrl!,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.45),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFFEF4444).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.timer_off_rounded,
                              size: 11, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            daysExpired == 0
                                ? 'Expired today'
                                : '${daysExpired}d ago',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CouponTypeBadge(type: coupon.type, small: true),
                  const SizedBox(height: 8),
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.monetization_on_outlined,
                          size: 14, color: AppColors.gold),
                      const SizedBox(width: 4),
                      Text(
                        '${coupon.pointsCost} pts',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Mono',
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${coupon.totalRedemptions} used',
                        style: const TextStyle(
                            color: AppColors.textMutedDark, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.event_busy_outlined,
                          size: 12, color: _amberLight),
                      const SizedBox(width: 4),
                      Text(
                        'Ended ${dateFormat.format(coupon.endDate)}',
                        style: const TextStyle(
                            color: _amberLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() => Container(
        height: 80,
        width: double.infinity,
        color: _amber.withValues(alpha: 0.08),
        child: Icon(coupon.type.icon,
            size: 32, color: _amber.withValues(alpha: 0.3)),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _ExpiredEmptyState extends StatelessWidget {
  const _ExpiredEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.timer_off_outlined,
                  size: 40, color: Color(0xFFFBBF24)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No expired coupons',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Great news! None of your coupons have expired yet.\nKeep creating engaging rewards.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppColors.textMutedDark, fontSize: 14, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
