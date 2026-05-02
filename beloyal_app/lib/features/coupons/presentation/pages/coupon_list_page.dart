import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import '../controllers/coupon_list_controller.dart';
import '../widgets/coupon_card.dart';

class CouponListPage extends ConsumerStatefulWidget {
  const CouponListPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends ConsumerState<CouponListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(couponListControllerProvider.notifier)
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
    final ctrl = ref.read(couponListControllerProvider.notifier);
    final state = ref.read(couponListControllerProvider);
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        state.hasMore &&
        !state.isLoadingMore) {
      ctrl.fetchCoupons(widget.businessId, reset: false);
    }
  }

  Future<void> _refresh() async {
    await ref
        .read(couponListControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _onSearchChanged(String query) {
    ref.read(couponListControllerProvider.notifier).updateSearch(query);
    ref
        .read(couponListControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _openDetail(CouponSummary coupon) {
    context.push('/business/${widget.businessId}/coupons/${coupon.id}');
  }

  void _openCreate() {
    context.push('/business/${widget.businessId}/coupons/create');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CouponListState>(couponListControllerProvider, (prev, next) {
      if (next.actionError != null && next.actionError != prev?.actionError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.actionError!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final state = ref.watch(couponListControllerProvider);
    final ctrl = ref.read(couponListControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: AppColors.bgDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
          tooltip: 'Back to dashboard',
          onPressed: () => context.go('/business/dashboard'),
        ),
        title: const Text(
          'Coupons',
          style: TextStyle(color: AppColors.textOnDark),
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
            onPressed: () => _showFilterSheet(context, state, ctrl),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primary),
            onPressed: _openCreate,
          ),
        ],
      ),
      body: Column(
        children: [
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
                        hintText: 'Search coupons...',
                        hintStyle: const TextStyle(
                          color: AppColors.textMutedDark,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textMutedDark,
                        ),
                        filled: true,
                        fillColor: AppColors.elevDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Active filters row
          if (state.statusFilter != null || state.typeFilter != null)
            _ActiveFiltersRow(state: state, ctrl: ctrl),

          // Sort bar
          _SortBar(state: state, ctrl: ctrl, businessId: widget.businessId),

          // List
          Expanded(
            child: state.isLoading && state.coupons.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : state.coupons.isEmpty
                ? _EmptyState(onCreate: _openCreate)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    color: AppColors.primary,
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 100, top: 8),
                      itemCount:
                          state.coupons.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == state.coupons.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }
                        final coupon = state.coupons[index];
                        return CouponCard(
                          coupon: coupon,
                          onTap: () => _openDetail(coupon),
                          onStatusChange: (status) => ctrl.changeStatus(
                            businessId: widget.businessId,
                            couponId: coupon.id,
                            status: status,
                          ),
                          onVisibilityChange: (visibility) =>
                              ctrl.changeVisibility(
                                businessId: widget.businessId,
                                couponId: coupon.id,
                                visibility: visibility,
                              ),
                          onDelete: () => _confirmDelete(context, coupon, ctrl),
                          onArchive: () => ctrl.archiveCoupon(
                            businessId: widget.businessId,
                            couponId: coupon.id,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _openCreate,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Coupon',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    CouponSummary coupon,
    CouponListController ctrl,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: const Text(
          'Delete Coupon',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: Text(
          'Are you sure you want to delete "${coupon.title}"?',
          style: const TextStyle(color: AppColors.textSubDark),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteCoupon(
                businessId: widget.businessId,
                couponId: coupon.id,
              );
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(
    BuildContext context,
    CouponListState state,
    CouponListController ctrl,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        state: state,
        onStatusChanged: (s) {
          ctrl.setStatusFilter(s);
          ctrl.fetchCoupons(widget.businessId);
          Navigator.pop(context);
        },
        onTypeChanged: (t) {
          ctrl.setTypeFilter(t);
          ctrl.fetchCoupons(widget.businessId);
          Navigator.pop(context);
        },
        onClear: () {
          ctrl.setStatusFilter(null);
          ctrl.setTypeFilter(null);
          ctrl.fetchCoupons(widget.businessId);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _ActiveFiltersRow extends StatelessWidget {
  const _ActiveFiltersRow({required this.state, required this.ctrl});

  final CouponListState state;
  final CouponListController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Wrap(
        spacing: 8,
        children: [
          if (state.statusFilter != null)
            Chip(
              label: Text(state.statusFilter!.displayName),
              labelStyle: TextStyle(
                color: state.statusFilter!.color,
                fontSize: 12,
              ),
              backgroundColor: state.statusFilter!.color.withValues(
                alpha: 0.15,
              ),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => ctrl.setStatusFilter(null),
            ),
          if (state.typeFilter != null)
            Chip(
              label: Text(state.typeFilter!.shortLabel),
              labelStyle: TextStyle(
                color: state.typeFilter!.color,
                fontSize: 12,
              ),
              backgroundColor: state.typeFilter!.color.withValues(alpha: 0.15),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => ctrl.setTypeFilter(null),
            ),
        ],
      ),
    );
  }
}

class _SortBar extends StatelessWidget {
  const _SortBar({
    required this.state,
    required this.ctrl,
    required this.businessId,
  });

  final CouponListState state;
  final CouponListController ctrl;
  final int businessId;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          for (final entry in {
            'createdAt': 'Date',
            'endDate': 'Expiry',
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
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: state.sortBy == entry.key
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.elevDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: state.sortBy == entry.key
                          ? AppColors.primary.withValues(alpha: 0.5)
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
                              ? AppColors.primary
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
                          color: AppColors.primary,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            const Text(
              'No coupons yet',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first coupon to start rewarding customers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Create Coupon'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.state,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  final CouponListState state;
  final void Function(CouponStatus?) onStatusChanged;
  final void Function(CouponType?) onTypeChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Filter Coupons',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton(onPressed: onClear, child: const Text('Clear All')),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Status',
              style: TextStyle(
                color: AppColors.textSubDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CouponStatus.values.map((s) {
                final isSelected = state.statusFilter == s;
                return GestureDetector(
                  onTap: () => onStatusChanged(isSelected ? null : s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? s.color.withValues(alpha: 0.2)
                          : AppColors.elevDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? s.color.withValues(alpha: 0.6)
                            : AppColors.glassBorder,
                      ),
                    ),
                    child: Text(
                      s.displayName,
                      style: TextStyle(
                        color: isSelected ? s.color : AppColors.textSubDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Type',
              style: TextStyle(
                color: AppColors.textSubDark,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CouponType.values.map((t) {
                final isSelected = state.typeFilter == t;
                return GestureDetector(
                  onTap: () => onTypeChanged(isSelected ? null : t),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
                        Icon(
                          t.icon,
                          size: 14,
                          color: isSelected ? t.color : AppColors.textSubDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          t.shortLabel,
                          style: TextStyle(
                            color: isSelected ? t.color : AppColors.textSubDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
    );
  }
}
