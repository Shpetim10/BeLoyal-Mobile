import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/point_transactions_controller.dart';

class TransactionFilterBar extends ConsumerWidget {
  const TransactionFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(txTypeFilterProvider);
    final activeCount = ref.watch(activeFilterCountProvider);

    return Container(
      color: AppColors.bgDark,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => ref
                      .read(txSearchQueryProvider.notifier)
                      .updateQuery(val),
                  style: const TextStyle(color: AppColors.textOnDark),
                  decoration: InputDecoration(
                    hintText: 'Search customer or invoice...',
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
              if (activeCount > 0)
                Badge(
                  label: Text(activeCount.toString()),
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    onPressed: () {
                      ref.read(txSearchQueryProvider.notifier).updateQuery('');
                      ref.read(txTypeFilterProvider.notifier).updateFilter(TxTypeFilter.all);
                      ref.read(txEmployeeFilterProvider.notifier).updateEmployee(null);
                      ref.read(txDateRangeProvider.notifier).updateDateRange(null);
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, color: AppColors.errorLight),
                    tooltip: 'Clear Filters',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: AppColors.glassBorder),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 12),
          
          // Filters Row
          SizedBox(
            height: 46,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  ...TxTypeFilter.values.map((type) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _TypeFilterChip(
                        type: type,
                        isSelected: typeFilter == type,
                        onSelected: () => ref.read(txTypeFilterProvider.notifier).updateFilter(type),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  const _EmployeeDropdownFilter(),
                  const SizedBox(width: 8),
                  const _DateRangeFilter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeFilterChip extends StatelessWidget {
  const _TypeFilterChip({
    required this.type,
    required this.isSelected,
    required this.onSelected,
  });

  final TxTypeFilter type;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    Color chipColor;
    switch (type) {
      case TxTypeFilter.earnBill:
      case TxTypeFilter.adjustmentPlus:
        chipColor = AppColors.secondary;
        break;
      case TxTypeFilter.redeemDiscount:
      case TxTypeFilter.redeemOffer:
        chipColor = AppColors.warning;
        break;
      case TxTypeFilter.expire:
      case TxTypeFilter.adjustmentMinus:
      case TxTypeFilter.reversal:
        chipColor = AppColors.error;
        break;
      case TxTypeFilter.all:
        chipColor = AppColors.primary;
        break;
    }

    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withValues(alpha: 0.15) : AppColors.surfaceDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.glassBorder,
          ),
        ),
        child: Text(
          type.displayName,
          style: TextStyle(
            color: isSelected ? chipColor : AppColors.textOnDark,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EmployeeDropdownFilter extends ConsumerWidget {
  const _EmployeeDropdownFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(uniqueEmployeeNamesProvider);
    final selected = ref.watch(txEmployeeFilterProvider);

    if (employees.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<String?>(
      tooltip: 'Filter by Staff',
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (val) => ref.read(txEmployeeFilterProvider.notifier).updateEmployee(val),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text(
            'All Staff',
            style: TextStyle(
              color: selected == null ? AppColors.primary : AppColors.textOnDark,
              fontWeight: selected == null ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        const PopupMenuDivider(),
        ...employees.map((name) {
          final isSelected = selected == name;
          return PopupMenuItem(
            value: name,
            child: Text(
              name,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textOnDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }),
      ],
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected != null ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected != null ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.badge_rounded, size: 16, color: selected != null ? AppColors.primary : AppColors.textOnDark),
            const SizedBox(width: 8),
            Text(
              selected ?? 'Staff',
              style: TextStyle(
                color: selected != null ? AppColors.primary : AppColors.textOnDark,
                fontWeight: selected != null ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateRangeFilter extends ConsumerWidget {
  const _DateRangeFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(txDateRangeProvider);
    final isSelected = range != null;

    final dateFormat = DateFormat('MMM d');
    final label = isSelected ? '${dateFormat.format(range.start)} - ${dateFormat.format(range.end)}' : 'Date';

    return GestureDetector(
      onTap: () async {
        final newRange = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          initialDateRange: range,
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.dark(
                  primary: AppColors.primary,
                  onPrimary: AppColors.textOnDark,
                  surface: AppColors.surfaceDark,
                  onSurface: AppColors.textOnDark,
                ),
                dialogBackgroundColor: AppColors.bgDark,
              ),
              child: child!,
            );
          },
        );
        if (newRange != null) {
          ref.read(txDateRangeProvider.notifier).updateDateRange(newRange);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceDark.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, size: 16, color: isSelected ? AppColors.primary : AppColors.textOnDark),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textOnDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
