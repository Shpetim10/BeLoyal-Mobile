import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import '../controllers/coupon_archived_controller.dart';
import 'coupon_detail_page.dart';
import '../widgets/coupon_status_chip.dart';

class CouponArchivedPage extends ConsumerStatefulWidget {
  const CouponArchivedPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponArchivedPage> createState() => _CouponArchivedPageState();
}

class _CouponArchivedPageState extends ConsumerState<CouponArchivedPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchVisible = false;
  bool _isRefreshingFromTop = false;

  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);
  static const _indigoLight = Color(0xFF818CF8);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(couponArchivedControllerProvider.notifier)
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
    final ctrl = ref.read(couponArchivedControllerProvider.notifier);
    final state = ref.read(couponArchivedControllerProvider);

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
        .read(couponArchivedControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _onSearchChanged(String query) {
    ref.read(couponArchivedControllerProvider.notifier).updateSearch(query);
    ref
        .read(couponArchivedControllerProvider.notifier)
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
        .read(couponArchivedControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponArchivedState>(couponArchivedControllerProvider,
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

    final state = ref.watch(couponArchivedControllerProvider);
    final ctrl = ref.read(couponArchivedControllerProvider.notifier);

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
                gradient: const LinearGradient(colors: [_indigo, _violet]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Archived',
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
                  _indigo.withValues(alpha: 0.15),
                  _violet.withValues(alpha: 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _indigo.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    color: _indigoLight, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Archived coupons are hidden from customers. Restore to bring them back as drafts.',
                    style: TextStyle(
                      color: Color(0xFFB4B8FF),
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
                        hintText: 'Search archived coupons...',
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
          _ArchivedSortBar(
              state: state, ctrl: ctrl, businessId: widget.businessId),

          // List
          Expanded(
            child: state.isLoading && state.coupons.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: _indigo))
                : state.coupons.isEmpty
                    ? const _ArchivedEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: _indigo,
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
                                      color: _indigo),
                                ),
                              );
                            }
                            final coupon = state.coupons[index];
                            return _ArchivedCouponCard(
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

  void _confirmRestore(
    CouponSummary coupon,
    CouponArchivedController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: _indigo, size: 22),
            SizedBox(width: 10),
            Text('Restore Coupon',
                style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Restore "${coupon.title}" back to draft? It will be available for editing and activation again.',
          style: const TextStyle(color: AppColors.textSubDark, height: 1.5),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _indigo,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context);
              ctrl.restoreFromArchive(
                businessId: widget.businessId,
                couponId: coupon.id,
              );
            },
            icon: const Icon(Icons.restore_rounded, size: 16),
            label: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    CouponSummary coupon,
    CouponArchivedController ctrl,
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
                businessId: widget.businessId,
                couponId: coupon.id,
              );
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
    CouponArchivedState state,
    CouponArchivedController ctrl,
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
                                fontWeight: FontWeight.w500,
                              )),
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

class _ArchivedDetailSheet extends StatelessWidget {
  const _ArchivedDetailSheet({
    required this.coupon,
    required this.onRestore,
    required this.onUpdate,
    required this.onDelete,
  });

  final CouponSummary coupon;
  final VoidCallback onRestore;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  static const _indigo = Color(0xFF6366F1);
  static const _violet = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

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
                            color: Colors.black.withValues(alpha: 0.35),
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
                              Colors.black.withValues(alpha: 0.45),
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
                          color: _indigo.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_rounded,
                                size: 11, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Archived',
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
                      const Icon(Icons.calendar_today_outlined,
                          size: 13, color: AppColors.textMutedDark),
                      const SizedBox(width: 6),
                      Text(
                        '${dateFormat.format(coupon.startDate)} – ${dateFormat.format(coupon.endDate)}',
                        style: const TextStyle(
                            color: AppColors.textMutedDark, fontSize: 13),
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
                        backgroundColor: _indigo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onRestore,
                      icon: const Icon(Icons.restore_rounded, size: 18),
                      label: const Text('Restore to Draft',
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _indigo.withValues(alpha: 0.15),
              _violet.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Icon(coupon.type.icon,
            size: 48, color: _indigo.withValues(alpha: 0.3)),
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

// ── Sort bar ──────────────────────────────────────────────────────────────────

class _ArchivedSortBar extends StatelessWidget {
  const _ArchivedSortBar({
    required this.state,
    required this.ctrl,
    required this.businessId,
  });

  final CouponArchivedState state;
  final CouponArchivedController ctrl;
  final int businessId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final entry in const {
            'archivedAt': 'Archived Date',
            'endDate': 'Expiry',
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
                        ? const Color(0xFF6366F1).withValues(alpha: 0.2)
                        : AppColors.elevDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.sortBy == entry.key
                          ? const Color(0xFF6366F1).withValues(alpha: 0.5)
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
                              ? const Color(0xFF818CF8)
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
                          color: const Color(0xFF818CF8),
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

class _ArchivedCouponCard extends StatelessWidget {
  const _ArchivedCouponCard({required this.coupon, required this.onTap});

  final CouponSummary coupon;
  final VoidCallback onTap;

  static const _indigo = Color(0xFF6366F1);

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
          border: Border.all(color: _indigo.withValues(alpha: 0.25)),
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
                          color: Colors.black.withValues(alpha: 0.35),
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
                        color: _indigo.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_rounded,
                              size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Archived',
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
        color: _indigo.withValues(alpha: 0.08),
        child: Icon(coupon.type.icon,
            size: 32, color: _indigo.withValues(alpha: 0.3)),
      );
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _ArchivedEmptyState extends StatelessWidget {
  const _ArchivedEmptyState();

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
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  size: 40, color: Color(0xFF818CF8)),
            ),
            const SizedBox(height: 20),
            const Text(
              'No archived coupons',
              style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Archived coupons will appear here.\nYou can restore them back to draft anytime.',
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
