import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/staff_controller.dart';

/// Sticky header containing search field, filter chips, and sorting dropdown.
class StaffSearchBar extends ConsumerWidget {
  const StaffSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(staffFilterProvider);

    return Container(
      color: AppColors.bgDark, // Solid background so lists don't show behind
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search & Sort Row ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => ref
                      .read(staffSearchQueryProvider.notifier)
                      .updateQuery(val),
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: InputDecoration(
                    hintText: 'Search staff by name or email',
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

          // ── Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: filter == StaffFilter.all,
                  onSelected: () => ref
                      .read(staffFilterProvider.notifier)
                      .updateFilter(StaffFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: filter == StaffFilter.active,
                  onSelected: () => ref
                      .read(staffFilterProvider.notifier)
                      .updateFilter(StaffFilter.active),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Inactive',
                  isSelected: filter == StaffFilter.inactive,
                  onSelected: () => ref
                      .read(staffFilterProvider.notifier)
                      .updateFilter(StaffFilter.inactive),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Invited/Pending',
                  isSelected: filter == StaffFilter.invited,
                  onSelected: () => ref
                      .read(staffFilterProvider.notifier)
                      .updateFilter(StaffFilter.invited),
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
    final sort = ref.watch(staffSortProvider);

    return PopupMenuButton<StaffSort>(
      icon: Icon(
        Icons.sort_rounded,
        color: sort != StaffSort.nameAZ
            ? AppColors.primary
            : AppColors.textMuted,
      ),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (val) => ref.read(staffSortProvider.notifier).updateSort(val),
      itemBuilder: (context) => [
        _buildItem(
          StaffSort.nameAZ,
          'Name (A–Z)',
          Icons.sort_by_alpha_rounded,
          sort,
        ),
        _buildItem(
          StaffSort.lastLogin,
          'Last Login (Recent)',
          Icons.access_time_rounded,
          sort,
        ),
        _buildItem(
          StaffSort.newestAdded,
          'Newest Added',
          Icons.fiber_new_rounded,
          sort,
        ),
      ],
    );
  }

  PopupMenuItem<StaffSort> _buildItem(
    StaffSort value,
    String label,
    IconData icon,
    StaffSort current,
  ) {
    final isSelected = value == current;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.primary : AppColors.textOnDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliver delegate to make the search bar sticky.
class StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  StickySearchBarDelegate();

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return const StaffSearchBar();
  }

  @override
  double get maxExtent => 110.0; // Approx height of the container

  @override
  double get minExtent => 110.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
