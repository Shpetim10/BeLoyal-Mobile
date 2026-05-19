import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../catalog_categories/data/catalog_category_repository.dart';
import '../controllers/catalog_item_controller.dart';
import '../widgets/catalog_item_card.dart';
import '../widgets/catalog_item_detail_sheet.dart';

class DeletedCatalogItemsPage extends ConsumerStatefulWidget {
  final int businessId;

  const DeletedCatalogItemsPage({super.key, required this.businessId});

  @override
  ConsumerState<DeletedCatalogItemsPage> createState() => _DeletedCatalogItemsPageState();
}

class _DeletedCatalogItemsPageState extends ConsumerState<DeletedCatalogItemsPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  
  String _searchQuery = '';
  int? _categoryIdFilter;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(deletedCatalogItemsProvider(widget.businessId));
  }

  @override
  Widget build(BuildContext context) {
    final deletedAsync = ref.watch(deletedCatalogItemsProvider(widget.businessId));
    final categoriesAsync = ref.watch(allCatalogCategoriesProvider(widget.businessId));

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Bar
              Padding(
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
                                'Deleted Items',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              if (deletedAsync.value != null && deletedAsync.value!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${deletedAsync.value!.length}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            'Trash Bin',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
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
                    controller: _searchCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: theme.textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search deleted items…',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? const SizedBox.shrink()
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
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
                      _buildCategoryChip('All Categories', _categoryIdFilter == null, () {
                        setState(() => _categoryIdFilter = null);
                      }),
                      
                      categoriesAsync.when(
                        data: (categories) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: categories.map((cat) {
                            return Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _buildCategoryChip(cat.name, _categoryIdFilter == cat.id, () {
                                setState(() => _categoryIdFilter = cat.id);
                              }),
                            );
                          }).toList(),
                        ),
                        loading: () => const Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: SizedBox(width: 24, height: 24, child: BesaLoader(size: 20)),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Content Area
              Expanded(
                child: deletedAsync.when(
                  loading: () => const Center(child: BesaLoader()),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: $err', style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (items) {
                    var filteredItems = items;
                    
                    if (_categoryIdFilter != null) {
                      filteredItems = filteredItems.where((item) => item.categoryId == _categoryIdFilter).toList();
                    }
                    
                    if (_searchQuery.trim().isNotEmpty) {
                      final query = _searchQuery.toLowerCase();
                      filteredItems = filteredItems.where((item) => item.name.toLowerCase().contains(query)).toList();
                    }

                    if (filteredItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_delete_outlined, size: 64, color: AppColors.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              items.isEmpty ? 'No deleted items.' : 'No items match your filters.',
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 16),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: _refresh,
                      color: AppColors.primary,
                      child: ListView.separated(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
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
                              ).whenComplete(() {
                                  ref.invalidate(deletedCatalogItemsProvider(widget.businessId));
                                  ref.read(catalogItemControllerProvider.notifier).fetchItems(widget.businessId);
                              });
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onSelected) {
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
        selectedColor: Colors.red.shade400,
        side: BorderSide(
          color: isSelected ? Colors.red.shade400 : AppColors.textMuted.withValues(alpha: 0.3),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
