import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../../core/utils/currency_utils.dart';
import '../controllers/catalog_item_variant_controller.dart';
import '../../data/models/catalog_item_variant_summary_response.dart';
import '../../data/models/catalog_item_variant_update_request.dart';

class CatalogItemVariantsSection extends ConsumerStatefulWidget {
  final int businessId;
  final int itemId;
  final String? currencyCode;
  final bool isReadOnly;

  const CatalogItemVariantsSection({
    super.key,
    required this.businessId,
    required this.itemId,
    this.currencyCode,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<CatalogItemVariantsSection> createState() => _CatalogItemVariantsSectionState();
}

class _CatalogItemVariantsSectionState extends ConsumerState<CatalogItemVariantsSection> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(catalogItemVariantControllerProvider(
                  VariantArg(businessId: widget.businessId, itemId: widget.itemId))
              .notifier)
          .fetchVariants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variantState = ref.watch(catalogItemVariantControllerProvider(
        VariantArg(businessId: widget.businessId, itemId: widget.itemId)));
    final variants = variantState.variants;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Variants',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Manage sizes, colors, or options',
                  style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
            // Explicitly using a more prominent button
            if (!widget.isReadOnly)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showVariantForm(context, ref),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'Add',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (variantState.isLoading && variants.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: BesaLoader(),
            ),
          )
        else if (variants.isEmpty)
          _buildEmptyState(context)
        else ...[
          if (!widget.isReadOnly) ...[
            Text(
              'Use the drag handle to reorder variants',
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
          ],
          if (variantState.isSubmitting) ...[
            const LinearProgressIndicator(minHeight: 2),
            const SizedBox(height: 10),
          ],
          _buildVariantsList(
            context,
            variants,
            canReorder: !widget.isReadOnly && !variantState.isSubmitting && !variantState.isLoading,
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(Icons.layers_outlined, size: 48, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 12),
          Text(
            'No variants configured',
            style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add variants to offer different options for this item',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
          if (!widget.isReadOnly) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _showVariantForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add your first variant'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantsList(
    BuildContext context,
    List<CatalogItemVariantSummaryResponse> variants, {
    required bool canReorder,
  }) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: variants.length,
        proxyDecorator: (child, index, animation) {
          return Material(
            elevation: 8,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: child,
          );
        },
        onReorder: (oldIndex, newIndex) {
          if (!canReorder) return;
          HapticFeedback.selectionClick();
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final items = List<CatalogItemVariantSummaryResponse>.from(variants);
          final item = items.removeAt(oldIndex);
          items.insert(newIndex, item);
          
          final orderedIds = items.map((v) => v.id).toList();
          ref.read(catalogItemVariantControllerProvider(VariantArg(businessId: widget.businessId, itemId: widget.itemId)).notifier)
            .reorderVariants(orderedIds);
        },
        itemBuilder: (context, index) {
          final variant = variants[index];
          final isActive = variant.status.toLowerCase() == 'active';
          final sym = currencySymbol(widget.currencyCode);

          return Material(
            key: ValueKey(variant.id),
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                border: index < variants.length - 1
                    ? Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.05)))
                    : null,
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: (isActive ? AppColors.primary : Colors.grey).withOpacity(0.5),
                    size: 20,
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        variant.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? null : Colors.grey,
                        ),
                      ),
                    ),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Inactive',
                          style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                subtitle: variant.description != null && variant.description!.isNotEmpty
                    ? Text(
                        variant.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canReorder)
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: Icon(Icons.drag_indicator_rounded, color: Colors.grey),
                      ),
                    if (variant.priceOverride != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          '$sym${variant.priceOverride!.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (!widget.isReadOnly)
                      PopupMenuButton<String>(
                        enabled: canReorder,
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                        onSelected: (value) => _handleMenuAction(context, ref, value, variant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        itemBuilder: (context) => [
                          _buildMenuItem('activate', isActive ? 'Deactivate' : 'Activate', 
                            isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                            isActive ? Colors.orange : Colors.green),
                          _buildMenuItem('edit', 'Edit', Icons.edit_outlined, Colors.blue),
                          _buildMenuItem('delete', variant.status.toLowerCase() == 'deleted' ? 'Restore' : 'Delete', 
                            variant.status.toLowerCase() == 'deleted' ? Icons.restore_from_trash : Icons.delete_outline,
                            variant.status.toLowerCase() == 'deleted' ? Colors.green : Colors.red),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, String label, IconData icon, Color color) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action, CatalogItemVariantSummaryResponse variant) {
    final notifier = ref.read(catalogItemVariantControllerProvider(VariantArg(businessId: widget.businessId, itemId: widget.itemId)).notifier);
    switch (action) {
      case 'activate':
        if (variant.status.toLowerCase() == 'active') {
          notifier.deactivateVariant(variant.id);
        } else {
          notifier.activateVariant(variant.id);
        }
        break;
      case 'edit':
        _showVariantForm(context, ref, variant: variant);
        break;
      case 'delete':
        if (variant.status.toLowerCase() == 'deleted') {
          notifier.restoreVariant(variant.id);
        } else {
          _showConfirmationDialog(
            context: context,
            title: 'Delete Variant',
            content: 'Are you sure you want to delete ${variant.name}?',
            onConfirm: () => notifier.deleteVariant(variant.id),
            isDestructive: true,
          );
        }
        break;
    }
  }

  void _showVariantForm(BuildContext context, WidgetRef ref, {CatalogItemVariantSummaryResponse? variant}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VariantFormSheet(
        businessId: widget.businessId,
        itemId: widget.itemId,
        initialVariant: variant,
      ),
    );
  }

  void _showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              backgroundColor: isDestructive ? Colors.red : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isDestructive ? 'Delete' : 'Confirm'),
          ),
        ],
      ),
    );
  }
}

class _VariantFormSheet extends ConsumerStatefulWidget {
  final int businessId;
  final int itemId;
  final CatalogItemVariantSummaryResponse? initialVariant;

  const _VariantFormSheet({
    required this.businessId,
    required this.itemId,
    this.initialVariant,
  });

  @override
  ConsumerState<_VariantFormSheet> createState() => _VariantFormSheetState();
}

class _VariantFormSheetState extends ConsumerState<_VariantFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialVariant?.name ?? '');
    _descController = TextEditingController(text: widget.initialVariant?.description ?? '');
    _priceController = TextEditingController(
      text: widget.initialVariant?.priceOverride != null ? widget.initialVariant!.priceOverride!.toStringAsFixed(2) : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final priceStr = _priceController.text.trim();
    final price = priceStr.isNotEmpty ? double.tryParse(priceStr) : null;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final isEditing = widget.initialVariant != null;

    final request = CatalogItemVariantUpdateRequest(
      catalogItemId: widget.itemId,
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      priceOverride: price,
    );

    final notifier = ref.read(catalogItemVariantControllerProvider(VariantArg(businessId: widget.businessId, itemId: widget.itemId)).notifier);
    
    try {
      if (isEditing) {
        await notifier.updateVariant(widget.initialVariant!.id, request);
      } else {
        await notifier.createVariant(request);
      }

      if (!mounted) return;

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Variant updated successfully.'
                : 'Variant created successfully.',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.initialVariant != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 40,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isEditing ? 'Edit Variant' : 'New Variant',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Define options for your product',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Variant Name',
                  hintText: 'e.g. XL, Red, 250ml',
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.label_important_outline_rounded),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Price Override (Optional)',
                  hintText: 'Keep empty for base price',
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (v) {
                  if (v != null && v.trim().isNotEmpty) {
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Short Description',
                  hintText: 'Optional details',
                  filled: true,
                  fillColor: Colors.grey.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  isEditing ? 'Save Changes' : 'Create Variant',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
