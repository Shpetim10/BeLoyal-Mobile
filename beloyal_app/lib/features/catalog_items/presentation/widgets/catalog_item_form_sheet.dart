import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/besa_loader.dart';
import '../../../catalog_categories/data/catalog_category_repository.dart';
import '../../../media/data/repositories/media_repository.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../profile/presentation/controllers/business_profile_controller.dart';
import '../../data/models/catalog_item_create_request.dart';
import '../../data/models/catalog_item_detail_response.dart';
import '../../data/models/catalog_item_type.dart';
import '../controllers/catalog_item_controller.dart';

class CatalogItemFormSheet extends ConsumerStatefulWidget {
  final int businessId;
  final int? initialCategoryId;
  final CatalogItemDetailResponse? initialItem;

  const CatalogItemFormSheet({
    super.key,
    required this.businessId,
    this.initialCategoryId,
    this.initialItem,
  });

  @override
  ConsumerState<CatalogItemFormSheet> createState() => _CatalogItemFormSheetState();
}

class _CatalogItemFormSheetState extends ConsumerState<CatalogItemFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();

  CatalogItemType _selectedType = CatalogItemType.product;
  String _selectedUnit = 'Piece';
  int? _selectedCategoryId;

  XFile? _selectedImage;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? widget.initialItem?.categoryId;
    
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      _nameController.text = item.name;
      _descController.text = item.description ?? '';
      _priceController.text = item.price.toString();
      _selectedUnit = item.unit ?? 'Piece';
      _selectedType = CatalogItemType.values.firstWhere(
        (e) => e.name.toUpperCase() == (item.type ?? 'PRODUCT'),
        orElse: () => CatalogItemType.product,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final notifier = ref.read(catalogItemControllerProvider.notifier);
    
    // 1. Upload image if selected
    String? imageUrl;
    String? imageKey;
    if (_selectedImage != null) {
      setState(() {
        _isUploadingImage = true;
      });
      try {
        final mediaRepo = ref.read(mediaRepositoryProvider);
        final result = await mediaRepo.uploadImage(
          file: _selectedImage!,
          category: 'MENU_ITEM',
          ownerId: widget.businessId,
        );
        imageUrl = result['url'];
        imageKey = result['key'];
      } catch (e) {
        setState(() {
          _isUploadingImage = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Image upload failed: $e')),
          );
        }
        return; // Stop submission if image upload fails
      }
    }

    // 2. Submit form
    final request = CatalogItemCreateRequest(
      name: _nameController.text,
      description: _descController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      type: _selectedType,
      unit: _selectedUnit,
      imageUrl: imageUrl,
      imageKey: imageKey,
    );

    try {
      if (widget.initialItem != null) {
        await notifier.updateItem(
          businessId: widget.businessId,
          itemId: widget.initialItem!.id,
          request: request,
        );
      } else {
        await notifier.createItem(
          businessId: widget.businessId,
          categoryId: _selectedCategoryId!,
          request: request,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.initialItem != null ? 'Item updated successfully' : 'Item created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Operation failed: $e')),
        );
      }
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogItemControllerProvider);
    final profileState = ref.watch(businessProfileControllerProvider);
    final businessCurrencyCode =
        profileState.value?.business?.currencyCode ?? 'ALL';
    final businessCurrencySymbol = currencySymbol(businessCurrencyCode);
    final activeCategoriesAsync = ref.watch(activeCatalogCategoriesProvider(widget.businessId));
    
    final isSubmitting = state.isSubmitting || _isUploadingImage;

    final theme = Theme.of(context);
    final sheetBg = theme.colorScheme.surface;

    // Provide a safe fallback if categories are still loading or have loaded
    final categories = activeCategoriesAsync.asData?.value ?? [];
    
    if (activeCategoriesAsync.hasValue && _selectedCategoryId != null) {
      if (!categories.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = null;
      }
    }

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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
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
                  widget.initialItem != null ? 'Update Catalog Item' : 'Add Catalog Item',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Image Picker
                Center(
                  child: GestureDetector(
                    onTap: !isSubmitting ? _pickImage : null,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedImage == null && widget.initialItem?.imageUrl == null
                              ? Colors.transparent
                              : theme.colorScheme.primary,
                        ),
                        image: _selectedImage != null
                            ? DecorationImage(
                                image: FileImage(File(_selectedImage!.path)),
                                fit: BoxFit.cover,
                              )
                            : widget.initialItem?.imageUrl != null
                                ? DecorationImage(
                                    image: NetworkImage(widget.initialItem!.imageUrl!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                      ),
                      child: _selectedImage == null && widget.initialItem?.imageUrl == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_outlined,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                TextFormField(
                  controller: _nameController,
                  enabled: !isSubmitting,
                  validator: (v) => v!.trim().isEmpty ? 'Enter item name' : null,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                activeCategoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<int>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: isSubmitting
                        ? null
                        : (val) {
                            setState(() {
                              _selectedCategoryId = val;
                            });
                          },
                    validator: (v) => v == null ? 'Select a category' : null,
                  ),
                  loading: () => const Center(child: BesaLoader()),
                  error: (err, _) => Text(
                    'Error loading categories',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
                const SizedBox(height: 16),

                // Type & Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<CatalogItemType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items: CatalogItemType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Text(t.displayName),
                          );
                        }).toList(),
                        onChanged: isSubmitting
                            ? null
                            : (val) {
                                if (val != null) setState(() => _selectedType = val);
                              },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _priceController,
                        enabled: !isSubmitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v!.trim().isEmpty) return 'Required';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0) return 'Invalid price';
                          return null;
                        },
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.attach_money),
                          suffixText: businessCurrencySymbol,
                          suffixStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Unit
                DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Piece', child: Text('Piece')),
                    DropdownMenuItem(value: 'Kg', child: Text('Kg')),
                    DropdownMenuItem(value: 'Hour', child: Text('Hour')),
                  ],
                  onChanged: isSubmitting
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descController,
                  enabled: !isSubmitting,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                FilledButton(
                  onPressed: isSubmitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: BesaLoader(size: 20),
                        )
                      : Text(
                          widget.initialItem != null ? 'Update Item' : 'Create Item',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
