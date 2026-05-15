import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import '../controllers/coupon_trash_controller.dart';
import 'coupon_detail_page.dart';
import '../widgets/coupon_status_chip.dart';

class CouponTrashPage extends ConsumerStatefulWidget {
  const CouponTrashPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponTrashPage> createState() => _CouponTrashPageState();
}

class _CouponTrashPageState extends ConsumerState<CouponTrashPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchVisible = false;
  bool _isRefreshingFromTop = false;

  static const _red = Color(0xFFDC2626);
  static const _redLight = Color(0xFFF87171);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(couponTrashControllerProvider.notifier)
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
    final ctrl = ref.read(couponTrashControllerProvider.notifier);
    final state = ref.read(couponTrashControllerProvider);

    if (_scrollCtrl.position.pixels <=
            50 &&
        !_isRefreshingFromTop &&
        !state.isLoading) {
      _isRefreshingFromTop = true;
      ctrl.fetchCoupons(widget.businessId).then((_) {
        _isRefreshingFromTop = false;
      });
    } else if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      ctrl.fetchCoupons(widget.businessId, reset: false);
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(couponTrashControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _onSearchChanged(String query) {
    ref.read(couponTrashControllerProvider.notifier).updateSearch(query);
    ref
        .read(couponTrashControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  Future<void> _openDetail(CouponSummary coupon) async {
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
    ref.read(couponTrashControllerProvider.notifier).fetchCoupons(widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponTrashState>(couponTrashControllerProvider, (prev, next) {
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

    final state = ref.watch(couponTrashControllerProvider);
    final ctrl = ref.read(couponTrashControllerProvider.notifier);

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
                    colors: [_red, Color(0xFFB91C1C)]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.delete_sweep_rounded,
                      size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Trash',
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
                  _red.withValues(alpha: 0.12),
                  _red.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _red.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _redLight, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Deleted coupons are kept here. Restore them to bring them back as drafts.',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
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
                        hintText: 'Search deleted coupons...',
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

          // List
          Expanded(
            child: state.isLoading && state.coupons.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _red))
                : state.coupons.isEmpty
                ? const _TrashEmptyState()
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: _red,
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
                              child: CircularProgressIndicator(color: _red),
                            ),
                          );
                        }
                        final coupon = state.coupons[index];
                        return _TrashCouponCard(
                          coupon: coupon,
                          onTap: () => _openDetail(coupon),
                          onRestore: () =>
                              _confirmRestore(context, coupon, ctrl),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(
    BuildContext context,
    CouponSummary coupon,
    CouponTrashController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_from_trash_rounded, color: _red, size: 22),
            SizedBox(width: 10),
            Text('Restore from Trash',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Restore "${coupon.title}"? It will be brought back as a draft coupon.',
          style: const TextStyle(color: AppColors.textSubDark, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ctrl.restoreFromTrash(
                businessId: widget.businessId,
                couponId: coupon.id,
              );
            },
            icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
            label: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showTypeFilterSheet(
    BuildContext context,
    CouponTrashState state,
    CouponTrashController ctrl,
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

// ── Card ──────────────────────────────────────────────────────────────────────

class _TrashCouponCard extends StatelessWidget {
  const _TrashCouponCard({
    required this.coupon,
    required this.onTap,
    required this.onRestore,
  });

  final CouponSummary coupon;
  final VoidCallback onTap;
  final VoidCallback onRestore;

  static const _red = Color(0xFFDC2626);
  static const _redLight = Color(0xFFF87171);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _red.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with trash badge
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
                          color: Colors.black.withValues(alpha: 0.5),
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
                        color: _red.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Deleted',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
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
                      const Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.textMutedDark),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(coupon.startDate)} – ${dateFormat.format(coupon.endDate)}',
                        style: const TextStyle(
                            color: AppColors.textMutedDark, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Single action: Restore
                  GestureDetector(
                    onTap: onRestore,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _red.withValues(alpha: 0.35)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restore_from_trash_rounded,
                              size: 15, color: _redLight),
                          SizedBox(width: 8),
                          Text(
                            'Restore from Trash',
                            style: TextStyle(
                              color: _redLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
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
        color: _red.withValues(alpha: 0.08),
        child: Icon(coupon.type.icon,
            size: 32, color: _red.withValues(alpha: 0.3)),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _TrashEmptyState extends StatelessWidget {
  const _TrashEmptyState();

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
                color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.delete_sweep_outlined,
                  size: 40, color: Color(0xFFF87171)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Trash is empty',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Deleted coupons will appear here.\nYou can restore them before they are permanently removed.',
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
