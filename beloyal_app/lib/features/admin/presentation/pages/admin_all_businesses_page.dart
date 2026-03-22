import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/admin_business_controller.dart';
import '../widgets/admin_business_card.dart';

class AdminAllBusinessesPage extends ConsumerStatefulWidget {
  const AdminAllBusinessesPage({super.key});

  @override
  ConsumerState<AdminAllBusinessesPage> createState() => _AdminAllBusinessesPageState();
}

class _AdminAllBusinessesPageState extends ConsumerState<AdminAllBusinessesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-sync text field if needed, but we keep it local until submit/change
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncBusinesses = ref.watch(adminAllBusinessesProvider);
    final filteredBusinesses = ref.watch(adminFilteredBusinessesProvider);
    final currentStatusFilter = ref.watch(adminBusinessStatusFilterProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits gradient from dashboard
      body: SafeArea(
        child: Column(
          children: [
            // ── Search & Filter Bar ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: AppColors.bgDark.withValues(alpha: 0.95),
                border: const Border(bottom: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Column(
                children: [
                  // Search Field
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(adminBusinessSearchQueryProvider.notifier).updateQuery(val);
                      },
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search businesses, emails, or phones...',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(adminBusinessSearchQueryProvider.notifier).updateQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status Filter Chips
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('All', AdminBusinessStatusFilter.all, currentStatusFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Active', AdminBusinessStatusFilter.active, currentStatusFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pending', AdminBusinessStatusFilter.pending, currentStatusFilter),
                        const SizedBox(width: 8),
                        _buildFilterChip('Rejected', AdminBusinessStatusFilter.rejected, currentStatusFilter),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Business List ──────────────────────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => ref.read(adminAllBusinessesProvider.notifier).refresh(),
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceDark,
                child: asyncBusinesses.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (err, stack) => _buildErrorState(err.toString()),
                  data: (_) {
                    if (filteredBusinesses.isEmpty) {
                      return ListView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                           SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          _buildEmptyState(),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: filteredBusinesses.length,
                      itemBuilder: (context, index) {
                        final biz = filteredBusinesses[index];
                        return AdminBusinessCard(
                          business: biz,
                          onTap: () {
                            context.push('/admin/businesses/${biz.id}');
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, AdminBusinessStatusFilter filterValue, AdminBusinessStatusFilter currentFilter) {
    final isSelected = currentFilter == filterValue;
    return GestureDetector(
      onTap: () {
        ref.read(adminBusinessStatusFilterProvider.notifier).updateFilter(filterValue);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          const Text(
            'No businesses found.',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search criteria.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.error.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          const Text(
            'Cannot load businesses',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => ref.read(adminAllBusinessesProvider.notifier).refresh(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
