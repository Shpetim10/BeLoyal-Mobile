import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../../../features/auth/domain/models/auth_user.dart';
import '../../data/models/catalog_category.dart';
import '../controllers/catalog_category_controller.dart';
import '../widgets/category_card.dart';
import '../widgets/category_detail_sheet.dart';
import '../widgets/category_empty_state.dart';
import '../widgets/category_form_sheet.dart';
import '../widgets/category_shimmer.dart';

/// Main screen for Catalog Category Management.
///
/// Role behaviour:
///   - [businessAdmin]: full list + create/edit/manage features.
///   - [staff]: read-only list + details bottom sheet.
class CatalogCategoryListPage extends ConsumerStatefulWidget {
  const CatalogCategoryListPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<CatalogCategoryListPage> createState() =>
      _CatalogCategoryListPageState();
}

class _CatalogCategoryListPageState
    extends ConsumerState<CatalogCategoryListPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isReorderMode = false;
  List<CatalogCategory> _localItems = [];

  @override
  void initState() {
    super.initState();
    // Fetch on first open (one-shot, not watch — manual refresh)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(catalogCategoryControllerProvider.notifier)
          .fetchCategories(widget.businessId);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  Future<void> _refresh() async {
    final isTrashView = ref.read(catalogCategoryControllerProvider).isTrashView;
    await ref
        .read(catalogCategoryControllerProvider.notifier)
        .fetchCategories(widget.businessId, trashView: isTrashView);
  }

  // ── Auto-scroll to newly created item ────────────────────────────────────

  void _maybeScrollToNew(int? lastCreatedId, List<CatalogCategory> categories) {
    if (lastCreatedId == null) return;
    final idx = categories.indexWhere((c) => c.id == lastCreatedId);
    if (idx < 0) return;

    // Approx 100px per card
    final targetOffset = (idx * 100.0).clamp(
      0.0,
      _scrollCtrl.position.maxScrollExtent,
    );

    _scrollCtrl.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );

    ref.read(catalogCategoryControllerProvider.notifier).clearLastCreatedId();
  }

  void _startReorderMode(List<CatalogCategory> items) {
    setState(() {
      _isReorderMode = true;
      _localItems = List<CatalogCategory>.from(items);
    });
  }

  Future<void> _saveReorder() async {
    final orderedIds = _localItems.map((e) => e.id).toList();
    setState(() {
      _isReorderMode = false;
    });
    ref
        .read(catalogCategoryControllerProvider.notifier)
        .reorderCategories(
          businessId: widget.businessId,
          orderedIds: orderedIds,
        );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // ── Error Feedback Listener ──────────────────────────────────────────────
    ref.listen<CatalogCategoryListState>(catalogCategoryControllerProvider, (
      previous,
      next,
    ) {
      if (next.error != null && next.error != previous?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    final state = ref.watch(catalogCategoryControllerProvider);
    final controller = ref.read(catalogCategoryControllerProvider.notifier);
    final session = ref.read(sessionControllerProvider);
    final isAdmin = session?.activeRole == UserRole.businessAdmin;
    final businessName = session?.activeBusinessName ?? 'Your Business';

    // Auto-scroll after create
    if (state.lastCreatedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeScrollToNew(state.lastCreatedId, state.categories);
      });
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isFiltered =
        state.searchQuery.isNotEmpty ||
        state.statusFilter != CategoryStatusFilter.all;
    final canReorder =
        isAdmin &&
        !state.isTrashView &&
        state.categories.length > 1 &&
        !isFiltered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App Bar ────────────────────────────────────────────────────
              _AppBar(
                businessName: businessName,
                categoryCount: state.categories.length,
                isAdmin: isAdmin && !_isReorderMode,
                isTrashView: state.isTrashView,
                onCreateTap: () => CategoryFormSheet.show(
                  context,
                  businessId: widget.businessId,
                  onSuccess: _refresh,
                ),
                onTrashToggle: () => controller.setTrashView(
                  businessId: widget.businessId,
                  enabled: !state.isTrashView,
                ),
                showReorderButton: canReorder && !_isReorderMode,
                onReorderTap: () => _startReorderMode(state.categories),
              ),

              if (_isReorderMode) ...[
                // ── Reorder Mode Actions ─────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.touch_app_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Drag handles to reorder items. Click Save when you are finished.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                setState(() => _isReorderMode = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: _saveReorder,
                            child: const Text(
                              'Save Order',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // ── Search ─────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: controller.updateSearchQuery,
                  ),
                ),

                // ── Filter Chips ───────────────────────────────────────────────
                if (!state.isTrashView)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                    child: _FilterChipRow(
                      selected: state.statusFilter,
                      onSelected: controller.updateStatusFilter,
                    ),
                  ),
              ],

              const SizedBox(height: 8),

              // ── Content area ───────────────────────────────────────────────
              Expanded(
                child: _isReorderMode
                    ? _buildReorderList()
                    : _buildBody(state: state, isAdmin: isAdmin),
              ),
            ],
          ),
        ),

        // ── FAB (Admin only) ──────────────────────────────────────────────
        floatingActionButton: (isAdmin && !_isReorderMode && !state.isTrashView)
            ? _CreateFAB(
                onTap: () => CategoryFormSheet.show(
                  context,
                  businessId: widget.businessId,
                  onSuccess: _refresh,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildReorderList() {
    return ReorderableListView.builder(
      scrollController: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _localItems.length,
      buildDefaultDragHandles: false,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final item = _localItems.removeAt(oldIndex);
          _localItems.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final cat = _localItems[index];
        return Padding(
          key: ValueKey(cat.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: CategoryCard(
            category: cat,
            animationIndex: index,
            isReorderable: true,
            onTap: () {},
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required CatalogCategoryListState state,
    required bool isAdmin,
  }) {
    // ── Loading ──────────────────────────────────────────────────────────────
    if (state.isLoading) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            children: [const SizedBox(height: 4), const CategoryShimmer()],
          ),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (state.hasError && state.categories.isEmpty) {
      return _ErrorState(message: state.error!, onRetry: _refresh);
    }

    // ── Empty ────────────────────────────────────────────────────────────────
    if (state.isEmpty) {
      return CategoryEmptyState(
        isAdmin: isAdmin,
        isFiltered:
            state.searchQuery.isNotEmpty ||
            state.statusFilter != CategoryStatusFilter.all,
        onCreateTap: () => CategoryFormSheet.show(
          context,
          businessId: widget.businessId,
          onSuccess: _refresh,
        ),
      );
    }

    // ── List ─────────────────────────────────────────────────────────────────
    final items = state.filteredCategories;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final cat = items[index];
          return CategoryCard(
            key: ValueKey(cat.id),
            category: cat,
            animationIndex: index,
            onTap: () => CategoryDetailSheet.show(
              context,
              category: cat,
              businessId: widget.businessId,
              isTrashView: state.isTrashView,
              onRefresh: _refresh,
            ),
          );
        },
      ),
    );
  }
}

// ── App Bar ───────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget {
  const _AppBar({
    required this.businessName,
    required this.categoryCount,
    required this.isAdmin,
    required this.isTrashView,
    required this.onCreateTap,
    required this.onTrashToggle,
    this.showReorderButton = false,
    this.onReorderTap,
  });

  final String businessName;
  final int categoryCount;
  final bool isAdmin;
  final bool isTrashView;
  final VoidCallback onCreateTap;
  final VoidCallback onTrashToggle;
  final bool showReorderButton;
  final VoidCallback? onReorderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          // ── Back ──────────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.glassBorder
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 14),

          // ── Title ─────────────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isTrashView ? 'Category Trash' : 'Catalog Categories',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (categoryCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$categoryCount',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  businessName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          GestureDetector(
            onTap: onTrashToggle,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isTrashView
                    ? AppColors.error.withValues(alpha: 0.14)
                    : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTrashView
                      ? AppColors.error.withValues(alpha: 0.35)
                      : (isDark
                            ? AppColors.glassBorder
                            : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Icon(
                isTrashView
                    ? Icons.restore_from_trash_rounded
                    : Icons.delete_outline_rounded,
                color: isTrashView ? AppColors.error : AppColors.textMuted,
                size: 21,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // ── Reorder button (Admin only) ───────────────────────────
          if (isAdmin && showReorderButton) ...[
            GestureDetector(
              onTap: onReorderTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? AppColors.glassBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

          // ── Create button (Admin only, compact) ───────────────────────────
          if (isAdmin)
            GestureDetector(
              onTap: onCreateTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withValues(alpha: 0.8)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Search categories…',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: ValueListenableBuilder(
            valueListenable: controller,
            builder: (_, val, __) => val.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ── Filter Chip Row ───────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.selected, required this.onSelected});

  final CategoryStatusFilter selected;
  final ValueChanged<CategoryStatusFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: CategoryStatusFilter.values.map((filter) {
          final isSelected = selected == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                label: Text(filter.label),
                onSelected: (_) => onSelected(filter),
                showCheckmark: false,
                avatar: isSelected
                    ? Icon(_filterIcon(filter), size: 14, color: Colors.white)
                    : null,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
                backgroundColor: Colors.transparent,
                selectedColor: AppColors.primary,
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textMuted.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _filterIcon(CategoryStatusFilter f) => switch (f) {
    CategoryStatusFilter.all => Icons.apps_rounded,
    CategoryStatusFilter.active => Icons.check_circle_outline_rounded,
    CategoryStatusFilter.inactive => Icons.pause_circle_outline_rounded,
  };
}

// ── Create FAB ────────────────────────────────────────────────────────────────

class _CreateFAB extends StatelessWidget {
  const _CreateFAB({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_rounded, color: Colors.white, size: 22),
                SizedBox(width: 8),
                Text(
                  'Add Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          duration: 400.ms,
          curve: Curves.elasticOut,
          delay: 300.ms,
        )
        .fadeIn(duration: 300.ms, delay: 200.ms);
  }
}

// ── Error State ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi_off_rounded,
                    color: AppColors.error,
                    size: 38,
                  ),
                )
                .animate()
                .scale(
                  begin: const Offset(0.7, 0.7),
                  duration: 450.ms,
                  curve: Curves.elasticOut,
                )
                .fadeIn(duration: 350.ms),

            const SizedBox(height: 20),
            Text(
                  'Failed to load categories',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate(delay: 100.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 8),
            Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                )
                .animate(delay: 160.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.2),

            const SizedBox(height: 28),
            OutlinedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                  ),
                )
                .animate(delay: 220.ms)
                .fadeIn(duration: 350.ms)
                .slideY(begin: 0.3),
          ],
        ),
      ),
    );
  }
}
