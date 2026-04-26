// Force-refresh timestamp: 2026-04-06T22:49:00Z
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/domain/models/auth_user.dart';
import '../../../../features/auth/presentation/controllers/session_controller.dart';
import '../../../catalog_categories/data/catalog_category_repository.dart';
import '../../data/models/catalog_item_short_response.dart';
import '../controllers/catalog_item_controller.dart';
import 'package:besahub_app/features/catalog_items/presentation/widgets/catalog_item_card.dart';
import 'package:besahub_app/features/catalog_items/presentation/widgets/catalog_item_detail_sheet.dart';
import 'package:besahub_app/features/catalog_items/presentation/widgets/catalog_item_form_sheet.dart';
import 'deleted_catalog_items_page.dart';

class CatalogItemListPage extends ConsumerStatefulWidget {
  final int businessId;

  const CatalogItemListPage({super.key, required this.businessId});

  @override
  ConsumerState<CatalogItemListPage> createState() => _CatalogItemListPageState();
}

class _CatalogItemListPageState extends ConsumerState<CatalogItemListPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _isReorderMode = false;
  List<CatalogItemShortResponse> _localItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(catalogItemControllerProvider.notifier).fetchItems(widget.businessId);
    });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(catalogItemControllerProvider.notifier).fetchItems(widget.businessId);
  }

  void _startReorderMode(List<CatalogItemShortResponse> items) {
    setState(() {
      _isReorderMode = true;
      _localItems = List<CatalogItemShortResponse>.from(items);
    });
  }

  Future<void> _saveReorder(int categoryId) async {
    final orderedIds = _localItems.map((e) => e.id).toList();
    setState(() {
      _isReorderMode = false;
    });
    ref.read(catalogItemControllerProvider.notifier).reorderItems(
          widget.businessId,
          categoryId,
          orderedIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CatalogItemListState>(
      catalogItemControllerProvider,
      (previous, next) {
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
      },
    );

    final state = ref.watch(catalogItemControllerProvider);
    final controller = ref.read(catalogItemControllerProvider.notifier);
    
    // Watch active categories directly from the new specifically scoped provider
    final activeCategoriesAsync = ref.watch(activeCatalogCategoriesProvider(widget.businessId));
    
    final session = ref.read(sessionControllerProvider);
    final isAdmin = session?.activeRole == UserRole.businessAdmin;
    final businessName = session?.activeBusinessName ?? 'Your Business';

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isFiltered = state.searchQuery.isNotEmpty;
    // We can only reorder if we are filtered to a specific category and have > 1 items
    final canReorder = isAdmin && 
                       state.categoryIdFilter != null && 
                       state.filteredItems.length > 1 && 
                       !isFiltered;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              _AppBar(
                businessName: businessName,
                itemCount: state.items.length,
                isAdmin: isAdmin && !_isReorderMode,
                onCreateTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CatalogItemFormSheet(
                      businessId: widget.businessId,
                      initialCategoryId: state.categoryIdFilter,
                    ),
                  );
                },
                showReorderButton: canReorder && !_isReorderMode,
                onReorderTap: () {
                  // Only items for the currently selected category can be reordered
                  _startReorderMode(state.filteredItems);
                },
                onTrashTap: isAdmin && !_isReorderMode ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeletedCatalogItemsPage(businessId: widget.businessId),
                    ),
                  );
                } : null,
              ),

              if (_isReorderMode) ...[
                // Reorder Mode Actions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Drag handles to reorder items within this category. Click Save when finished.',
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
                            onPressed: () => setState(() => _isReorderMode = false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () => _saveReorder(state.categoryIdFilter!),
                            child: const Text('Save Order', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Search
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: _SearchBar(
                    controller: _searchCtrl,
                    onChanged: controller.updateSearchQuery,
                  ),
                ),

                // Category Chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'All Categories',
                          isSelected: state.categoryIdFilter == null,
                          onSelected: () => controller.filterByCategory(null, null),
                        ),
                        
                        activeCategoriesAsync.when(
                          data: (categories) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: categories.map((cat) {
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: _CategoryChip(
                                  label: cat.name,
                                  isSelected: state.categoryIdFilter == cat.id,
                                  onSelected: () => controller.filterByCategory(cat.id, cat.name),
                                ),
                              );
                            }).toList(),
                          ),
                          loading: () => const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              // Content Area
              Expanded(
                child: _isReorderMode
                    ? _buildReorderList()
                    : _buildBody(state: state, isAdmin: isAdmin),
              ),
            ],
          ),
        ),
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
          if (oldIndex < newIndex) newIndex -= 1;
          final item = _localItems.removeAt(oldIndex);
          _localItems.insert(newIndex, item);
        });
      },
      itemBuilder: (context, index) {
        final item = _localItems[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 12),
          child: CatalogItemCard(
            item: item,
            animationIndex: index,
            isReorderable: true,
            onTap: () {}, // disabled during reorder
          ),
        );
      },
    );
  }

  Widget _buildBody({required CatalogItemListState state, required bool isAdmin}) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.filteredItems.isEmpty) {
      return const Center(
        child: Text('No items found.', style: TextStyle(color: AppColors.textMuted)),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.filteredItems.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = state.filteredItems[index];
          return CatalogItemCard(
            key: ValueKey(item.id),
            item: item,
            animationIndex: index,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CatalogItemDetailSheet(
                  businessId: widget.businessId,
                  itemId: item.id,
                ),
              );
            },
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
    required this.itemCount,
    required this.isAdmin,
    required this.onCreateTap,
    this.showReorderButton = false,
    this.onReorderTap,
    this.onTrashTap,
  });

  final String businessName;
  final int itemCount;
  final bool isAdmin;
  final VoidCallback onCreateTap;
  final bool showReorderButton;
  final VoidCallback? onReorderTap;
  final VoidCallback? onTrashTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Catalog Items',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                    if (itemCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$itemCount',
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),

          if (onTrashTap != null) ...[
            GestureDetector(
              onTap: onTrashTap,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],

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
                    color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
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
        color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white,
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
          hintText: 'Search items…',
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
                    icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                    onPressed: () {
                      controller.clear();
                      onChanged('');
                    },
                  ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ── Category Chip ─────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (_) => onSelected(),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textMuted,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        ),
        backgroundColor: Colors.transparent,
        selectedColor: AppColors.primary,
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.textMuted.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
