import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/catalog_categories/data/catalog_category_repository.dart';
import '../../../../core/theme/app_colors.dart';

class MoveCategorySheet extends ConsumerStatefulWidget {
  final int businessId;
  final int itemId;
  final String itemName;
  final String? currentCategoryName;
  final Function(int categoryId, String categoryName) onMove;

  const MoveCategorySheet({
    super.key,
    required this.businessId,
    required this.itemId,
    required this.itemName,
    this.currentCategoryName,
    required this.onMove,
  });

  @override
  ConsumerState<MoveCategorySheet> createState() => _MoveCategorySheetState();
}

class _MoveCategorySheetState extends ConsumerState<MoveCategorySheet> {
  int? _selectedCategoryId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCategoriesAsync = ref.watch(activeCatalogCategoriesProvider(widget.businessId));

    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.colorScheme.surface;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 40,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Move Category',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a new category for ${widget.itemName}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.textMuted : Colors.grey[600],
                ),
              ),
            if (widget.currentCategoryName != null) ...[
              const SizedBox(height: 8),
              Text(
                'Current Category: ${widget.currentCategoryName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ],
            const SizedBox(height: 24),
            activeCategoriesAsync.when(
              data: (categories) => DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: categories
                    .map((cat) => DropdownMenuItem(
                          value: cat.id,
                          child: Text(cat.name),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategoryId = val;
                  });
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error loading categories', style: TextStyle(color: Colors.red))),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedCategoryId == null
                    ? null
                    : () {
                        final categories = activeCategoriesAsync.asData?.value ?? [];
                        final catName = categories
                            .firstWhere((c) => c.id == _selectedCategoryId)
                            .name;
                        widget.onMove(_selectedCategoryId!, catName);
                        Navigator.pop(context);
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Move Item',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
