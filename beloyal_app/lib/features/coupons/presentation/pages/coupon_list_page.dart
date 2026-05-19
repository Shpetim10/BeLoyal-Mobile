import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../features/auth/domain/models/auth_user.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import '../controllers/coupon_list_controller.dart';
import 'coupon_detail_page.dart';
import '../widgets/coupon_card.dart';

class CouponListPage extends ConsumerStatefulWidget {
  const CouponListPage({
    super.key,
    required this.businessId,
    this.embedded = false,
  });

  final int businessId;
  final bool embedded;

  @override
  ConsumerState<CouponListPage> createState() => _CouponListPageState();
}

class _CouponListPageState extends ConsumerState<CouponListPage> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _isSearchVisible = false;
  bool _isTopControlsExpanded = false;
  bool _isStaff = false;
  bool _isRefreshingFromTop = false;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionControllerProvider);
    _isStaff = session?.activeRole == UserRole.staff;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isStaff) {
        ref.read(couponListControllerProvider.notifier).setStatusFilter(
          CouponStatus.active,
        );
      }
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
        .read(couponListControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _onSearchChanged(String query) {
    ref.read(couponListControllerProvider.notifier).updateSearch(query);
    ref
        .read(couponListControllerProvider.notifier)
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
    ref
        .read(couponListControllerProvider.notifier)
        .fetchCoupons(widget.businessId);
  }

  void _openCreate() {
    if (_isStaff) return;
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
    final allowedStatuses = _isStaff
        ? const [CouponStatus.active, CouponStatus.expired]
        : CouponStatus.values;

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: widget.embedded
          ? null
          : AppBar(
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
            ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Top Control Bar: Filter Toggle | Scan Button | Add Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Filter Toggle Button (Expanded)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                          () => _isTopControlsExpanded = !_isTopControlsExpanded,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.elevDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                size: 16,
                                color: AppColors.textMutedDark,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _isTopControlsExpanded ? 'Hide' : 'Filters',
                                  style: const TextStyle(
                                    color: AppColors.textMutedDark,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                _isTopControlsExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                size: 16,
                                color: AppColors.textMutedDark,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Scan Coupon Button (with text)
                    GestureDetector(
                      onTap: () => context.push(
                        _isStaff ? '/staff/scan-coupon' : '/business/scan-coupon',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Scan',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Add Button (Admin Only)
                    if (!_isStaff)
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _openCreate,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        tooltip: 'New Coupon',
                      ),
                  ],
                ),
              ),
              _FilterSection(
                isExpanded: _isTopControlsExpanded,
                hasActiveFilters:
                    state.statusFilter != null || state.typeFilter != null,
                onToggle: () => setState(
                  () => _isTopControlsExpanded = !_isTopControlsExpanded,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _isSearchVisible = !_isSearchVisible,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.elevDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.search,
                                      size: 16,
                                      color: AppColors.textMutedDark,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Search rewards...',
                                      style: TextStyle(
                                        color: AppColors.textMutedDark,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.filter_list,
                              color: AppColors.textOnDark,
                            ),
                            onPressed: () =>
                                _showFilterSheet(
                                  context,
                                  state,
                                  ctrl,
                                  allowedStatuses,
                                ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.elevDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(
                                  color: AppColors.glassBorder,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!_isStaff)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _QuickAccessCard(
                                label: 'Archived',
                                icon: Icons.inventory_2_rounded,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                ),
                                onTap: () => context.push(
                                  '/business/${widget.businessId}/coupons/archived',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAccessCard(
                                label: 'Expired',
                                icon: Icons.timer_off_rounded,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                ),
                                onTap: () => context.push(
                                  '/business/${widget.businessId}/coupons/expired',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAccessCard(
                                label: 'Trash',
                                icon: Icons.delete_sweep_rounded,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                                ),
                                onTap: () => context.push(
                                  '/business/${widget.businessId}/coupons/trash',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isSearchVisible
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: TextField(
                                controller: _searchCtrl,
                                style: const TextStyle(
                                  color: AppColors.textOnDark,
                                ),
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
                    if (state.statusFilter != null || state.typeFilter != null)
                      _ActiveFiltersRow(state: state, ctrl: ctrl),
                    _SortBar(
                      state: state,
                      ctrl: ctrl,
                      businessId: widget.businessId,
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: state.isLoading && state.coupons.isEmpty
                    ? const Center(child: BesaLoader())
                    : state.coupons.isEmpty
                    ? _EmptyState(onCreate: _openCreate, readOnly: _isStaff)
                    : RefreshIndicator(
                        onRefresh: _refresh,
                        color: AppColors.primary,
                        child: ListView.builder(
                          controller: _scrollCtrl,
                          padding: const EdgeInsets.only(bottom: 100, top: 8),
                          itemCount:
                              state.coupons.length +
                              (state.isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == state.coupons.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: BesaLoader(size: 24)),
                              );
                            }
                            final coupon = state.coupons[index];
                            return CouponCard(
                              coupon: coupon,
                              readOnly: _isStaff,
                              onTap: () => _openDetail(coupon),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
          if (widget.embedded && !_isStaff)
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).viewPadding.bottom + 70,
              child: FloatingActionButton.extended(
                heroTag: 'besa-fab-coupon-embedded',
                backgroundColor: AppColors.primary,
                onPressed: _openCreate,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'New Coupon',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: widget.embedded || _isStaff
          ? null
          : FloatingActionButton.extended(
              heroTag: 'besa-fab-coupon-page',
              backgroundColor: AppColors.primary,
              onPressed: _openCreate,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'New Coupon',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
    );
  }

  void _showFilterSheet(
    BuildContext context,
    CouponListState state,
    CouponListController ctrl,
    List<CouponStatus> allowedStatuses,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _FilterSheet(
        state: state,
        allowedStatuses: allowedStatuses,
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
          ctrl.setStatusFilter(_isStaff ? CouponStatus.active : null);
          ctrl.setTypeFilter(null);
          ctrl.fetchCoupons(widget.businessId);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTight = constraints.maxWidth < 120;
          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTight ? 10 : 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: gradient.colors
                    .map((c) => c.withValues(alpha: 0.15))
                    .toList(),
              ),
              border: Border.all(
                color: gradient.colors.first.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => gradient.createShader(bounds),
                  child: Icon(
                    icon,
                    size: isTight ? 14 : 16,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: isTight ? 6 : 8),
                Flexible(
                  child: ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTight ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (!isTight) ...[
                  const SizedBox(width: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => gradient.createShader(bounds),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          );
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

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.isExpanded,
    required this.hasActiveFilters,
    required this.onToggle,
    required this.child,
  });

  final bool isExpanded;
  final bool hasActiveFilters;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 200),
      crossFadeState: isExpanded
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      firstChild: child,
      secondChild: const SizedBox.shrink(),
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
  const _EmptyState({required this.onCreate, required this.readOnly});

  final VoidCallback onCreate;
  final bool readOnly;

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
              'No coupons found',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              readOnly
                  ? 'No active or expired coupons are available right now.'
                  : 'Create your first coupon to start rewarding customers.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMutedDark,
                fontSize: 14,
              ),
            ),
            if (!readOnly) ...[
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
          ],
        ),
      ),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.state,
    required this.allowedStatuses,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onClear,
  });

  final CouponListState state;
  final List<CouponStatus> allowedStatuses;
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
              children: allowedStatuses.map((s) {
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
