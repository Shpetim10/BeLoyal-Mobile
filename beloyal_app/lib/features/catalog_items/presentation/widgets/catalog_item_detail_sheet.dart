import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';

import '../controllers/catalog_item_controller.dart';
import '../../data/models/catalog_item_status.dart';
import 'catalog_item_form_sheet.dart';
import 'catalog_item_variants_section.dart';
import 'move_category_sheet.dart';

class CatalogItemDetailSheet extends ConsumerWidget {
  final int businessId;
  final int itemId;

  const CatalogItemDetailSheet({
    super.key,
    required this.businessId,
    required this.itemId,
  });

  String _currencyDisplayText(String? currencyCode) {
    final code = currencyCode?.trim().toUpperCase();
    switch (code) {
      case 'EURO':
      case 'EUR':
        return 'Euro (EUR)';
      case 'DOLLAR':
      case 'USD':
        return 'Dollar (USD)';
      case 'LEK':
      case 'ALL':
        return 'Lek (ALL)';
      default:
        return currencyCode?.trim() ?? '';
    }
  }

  String _formatMainPrice(double price, String? currencyCode) {
    final displayCurrency = _currencyDisplayText(currencyCode);
    if (displayCurrency.isEmpty) {
      return price.toStringAsFixed(2);
    }
    return '${price.toStringAsFixed(2)} $displayCurrency';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(catalogItemDetailProvider((businessId: businessId, itemId: itemId)));
    final theme = Theme.of(context);
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
        child: detailAsync.when(
          loading: () => const SizedBox(
            height: 300,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => SizedBox(
            height: 300,
            child: Center(child: Text('Failed to load item info: $err')),
          ),
          data: (item) {
            final isDeleted = item.isDeleted || item.status == CatalogItemStatus.deleted;
            final isActive = item.status == CatalogItemStatus.active && !isDeleted;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                // Image Header
                if (item.imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      image: DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isActive ? Colors.green : (isDeleted ? Colors.red : Colors.grey)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          item.status.displayName,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isActive ? Colors.green : (isDeleted ? Colors.red : Colors.grey),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            Icons.payments_outlined,
                            size: 20,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatMainPrice(item.price, item.currencyCode),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (item.categoryName != null) ...[
                        _DetailFieldRow(
                          icon: Icons.category_outlined,
                          text: item.categoryName!,
                          textStyle: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (item.description != null && item.description!.isNotEmpty) ...[
                        _DetailFieldRow(
                          icon: Icons.notes_rounded,
                          text: item.description!,
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      CatalogItemVariantsSection(
                        businessId: businessId,
                        itemId: itemId,
                        currencyCode: item.currencyCode,
                      ),

                      // Action Panel
                      if (!isDeleted) ...[
                        const Divider(height: 48),
                        Text(
                          'Actions',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _ActionIconButton(
                              icon: isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                              label: isActive ? 'Deactivate' : 'Activate',
                              color: isActive ? Colors.orange : Colors.green,
                              onTap: () => _showConfirmationDialog(
                                context,
                                ref,
                                title: isActive ? 'Deactivate Item' : 'Activate Item',
                                content: 'Are you sure you want to ${isActive ? 'deactivate' : 'activate'} this item?',
                                onConfirm: () {
                                  if (isActive) {
                                    ref.read(catalogItemControllerProvider.notifier).deactivateItem(businessId, itemId);
                                  } else {
                                    ref.read(catalogItemControllerProvider.notifier).activateItem(businessId, itemId);
                                  }
                                  Navigator.pop(context); // Close detail sheet
                                },
                              ),
                            ),
                            _ActionIconButton(
                              icon: Icons.edit,
                              label: 'Update',
                              color: Colors.blue,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => CatalogItemFormSheet(
                                    businessId: businessId,
                                    initialItem: item,
                                  ),
                                );
                              },
                            ),
                            _ActionIconButton(
                              icon: Icons.drive_file_move_outline,
                              label: 'Move',
                              color: Colors.purple,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => MoveCategorySheet(
                                    businessId: businessId,
                                    itemId: itemId,
                                    itemName: item.name,
                                    currentCategoryName: item.categoryName,
                                    onMove: (catId, catName) {
                                      ref.read(catalogItemControllerProvider.notifier).moveCategory(businessId, itemId, catId, catName);
                                      Navigator.pop(context); // close Detail sheet
                                    },
                                  ),
                                );
                              },
                            ),
                            _ActionIconButton(
                              icon: Icons.delete_outline,
                              label: 'Delete',
                              color: Colors.red,
                              onTap: () => _showConfirmationDialog(
                                context,
                                ref,
                                title: 'Delete Item',
                                content: 'Are you sure you want to delete this item?',
                                isDestructive: true,
                                onConfirm: () {
                                  ref.read(catalogItemControllerProvider.notifier).deleteItem(businessId, itemId);
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const Divider(height: 32),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'This item is in the trash and will not be visible to customers.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  icon: const Icon(Icons.restore_from_trash_rounded),
                                  label: const Text(
                                    'Restore Item',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () {
                                    ref.read(catalogItemControllerProvider.notifier).restoreItem(businessId, itemId);
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                    ],
                  ),
                ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? AppColors.error : theme.colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailFieldRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? textStyle;

  const _DetailFieldRow({
    required this.icon,
    required this.text,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}



