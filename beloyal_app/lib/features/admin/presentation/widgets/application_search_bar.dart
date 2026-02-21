import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/applications_controller.dart';

class ApplicationSearchBar extends ConsumerWidget {
  const ApplicationSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(appFilterProvider);

    return Container(
      color: AppColors.bgDark,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => ref
                      .read(appSearchQueryProvider.notifier)
                      .updateQuery(val),
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: InputDecoration(
                    hintText: 'Search by name, email, phone',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textMuted,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceDark.withValues(alpha: 0.6),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.glassBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SortDropdown(),
            ],
          ),
          const SizedBox(height: 12),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'Pending',
                  isSelected: filter == ApplicationFilter.pending,
                  onSelected: () => ref
                      .read(appFilterProvider.notifier)
                      .updateFilter(ApplicationFilter.pending),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'All (Coming Soon)',
                  isSelected: filter == ApplicationFilter.all,
                  onSelected: () {
                    // Placeholder for future functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All applications view coming soon!'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textOnDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(appSortProvider);

    return PopupMenuButton<ApplicationSort>(
      icon: Icon(
        Icons.sort_rounded,
        color: sort != ApplicationSort.newest
            ? AppColors.primary
            : AppColors.textMuted,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (val) => ref.read(appSortProvider.notifier).updateSort(val),
      itemBuilder: (context) => [
        _buildItem(
          ApplicationSort.newest,
          'Newest First',
          Icons.arrow_downward_rounded,
          sort,
        ),
        _buildItem(
          ApplicationSort.oldest,
          'Oldest First',
          Icons.arrow_upward_rounded,
          sort,
        ),
        _buildItem(
          ApplicationSort.nameAZ,
          'Name (A–Z)',
          Icons.sort_by_alpha_rounded,
          sort,
        ),
      ],
    );
  }

  PopupMenuItem<ApplicationSort> _buildItem(
    ApplicationSort value,
    String label,
    IconData icon,
    ApplicationSort currentSort,
  ) {
    final isSelected = value == currentSort;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textOnDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
