import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/coupon_repository.dart';
import '../../data/models/coupon_detail.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_lookup_models.dart';

class CouponUpdateSheet extends ConsumerStatefulWidget {
  const CouponUpdateSheet({
    super.key,
    required this.businessId,
    required this.coupon,
    required this.onUpdated,
  });

  final int businessId;
  final CouponDetail coupon;
  final VoidCallback onUpdated;

  @override
  ConsumerState<CouponUpdateSheet> createState() => _CouponUpdateSheetState();
}

class _CouponUpdateSheetState extends ConsumerState<CouponUpdateSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _pointsCtrl;
  late final TextEditingController _termsCtrl;
  late final TextEditingController _totalLimitCtrl;
  late final TextEditingController _perCustomerLimitCtrl;
  late final TextEditingController _sortOrderCtrl;

  late final TextEditingController _discountPctCtrl;
  late final TextEditingController _discountAmountCtrl;
  late final TextEditingController _minimumOrderCtrl;
  late final TextEditingController _maximumDiscountCtrl;
  late final TextEditingController _quantityCtrl;

  late CouponType _type;
  late CouponStatus _status;
  late CouponVisibility _visibility;
  late bool _isFeatured;
  late DateTime _startDate;
  late DateTime _endDate;

  int? _selectedCategoryId;
  int? _selectedProductId;
  int? _selectedVariantId;

  List<CategoryLookup> _categories = const [];
  List<ProductLookup> _products = const [];
  List<VariantLookup> _variants = const [];

  bool _isSaving = false;
  bool _isUploadingImage = false;
  bool _loadingCategories = false;
  bool _loadingProducts = false;
  bool _loadingVariants = false;
  String? _uploadedImageUrl;

  final Set<int> _expanded = {0};

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _type = c.type;
    _status = c.status;
    _visibility = c.visibility;
    _isFeatured = c.isFeatured;
    _startDate = c.startDate;
    _endDate = c.endDate;

    _titleCtrl = TextEditingController(text: c.title);
    _descriptionCtrl = TextEditingController(text: c.description ?? '');
    _uploadedImageUrl = c.imageUrl;
    _pointsCtrl = TextEditingController(text: c.pointsCost.toString());
    _termsCtrl = TextEditingController(text: c.termsAndConditions ?? '');
    _totalLimitCtrl =
        TextEditingController(text: c.totalRedemptionLimit?.toString() ?? '');
    _perCustomerLimitCtrl = TextEditingController(
      text: c.perCustomerRedemptionLimit?.toString() ?? '',
    );
    _sortOrderCtrl = TextEditingController(text: c.sortOrder?.toString() ?? '');

    _discountPctCtrl = TextEditingController(
      text: c.discountDetails?.discountPercentage?.toString() ?? '',
    );
    _discountAmountCtrl = TextEditingController(
      text: c.discountDetails?.discountAmount?.toString() ?? '',
    );
    _minimumOrderCtrl = TextEditingController(
      text: c.discountDetails?.minimumOrderAmount?.toString() ?? '',
    );
    _maximumDiscountCtrl = TextEditingController(
      text: c.discountDetails?.maximumDiscountAmount?.toString() ?? '',
    );
    _quantityCtrl = TextEditingController(
      text: c.freeProductDetails?.quantity.toString() ?? '1',
    );

    _selectedCategoryId = c.freeProductDetails?.categoryId;
    _selectedProductId = c.freeProductDetails?.productId;
    _selectedVariantId = c.freeProductDetails?.variantId;

    _loadLookups();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _pointsCtrl.dispose();
    _termsCtrl.dispose();
    _totalLimitCtrl.dispose();
    _perCustomerLimitCtrl.dispose();
    _sortOrderCtrl.dispose();
    _discountPctCtrl.dispose();
    _discountAmountCtrl.dispose();
    _minimumOrderCtrl.dispose();
    _maximumDiscountCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    if (_type != CouponType.freeProduct) return;
    final repo = ref.read(couponRepositoryProvider);
    setState(() => _loadingCategories = true);
    try {
      final categories = await repo.lookupCategories(businessId: widget.businessId);
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _loadingCategories = false;
      });

      if (_selectedCategoryId != null) {
        await _loadProducts(_selectedCategoryId!);
      }
      if (_selectedProductId != null) {
        await _loadVariants(_selectedProductId!);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadProducts(int categoryId) async {
    final repo = ref.read(couponRepositoryProvider);
    setState(() {
      _loadingProducts = true;
      _products = const [];
      _variants = const [];
      _selectedProductId = null;
      _selectedVariantId = null;
    });
    try {
      final products = await repo.lookupProducts(
        businessId: widget.businessId,
        categoryId: categoryId,
      );
      if (!mounted) return;
      setState(() {
        _products = products;
        _loadingProducts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProducts = false);
    }
  }

  Future<void> _loadVariants(int productId) async {
    final repo = ref.read(couponRepositoryProvider);
    setState(() {
      _loadingVariants = true;
      _variants = const [];
      _selectedVariantId = null;
    });
    try {
      final variants = await repo.lookupVariants(
        businessId: widget.businessId,
        productId: productId,
      );
      if (!mounted) return;
      setState(() {
        _variants = variants;
        _loadingVariants = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingVariants = false);
    }
  }

  int? _parseInt(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return int.tryParse(v);
  }

  double? _parseDouble(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return null;
    return double.tryParse(v);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate.add(const Duration(days: 1));
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;

    setState(() => _isUploadingImage = true);
    try {
      final uploaded = await ref.read(couponRepositoryProvider).uploadCouponImage(
            businessId: widget.businessId,
            file: file,
          );
      if (!mounted) return;
      setState(() => _uploadedImageUrl = uploaded.url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final points = _parseInt(_pointsCtrl.text);
    if (title.isEmpty || points == null || points <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and a valid points cost are required.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End date must be after start date.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final updates = <String, dynamic>{
      'type': _type.backendValue,
      'title': title,
      'description': _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      'imageUrl': _uploadedImageUrl,
      'pointsCost': points,
      'startDate': _startDate.toUtc().toIso8601String(),
      'endDate': _endDate.toUtc().toIso8601String(),
      'status': _status.backendValue,
      'visibility': _visibility.backendValue,
      'termsAndConditions': _termsCtrl.text.trim().isEmpty
          ? null
          : _termsCtrl.text.trim(),
      'isFeatured': _isFeatured,
      'sortOrder': _parseInt(_sortOrderCtrl.text),
      'totalRedemptionLimit': _parseInt(_totalLimitCtrl.text),
      'perCustomerRedemptionLimit': _parseInt(_perCustomerLimitCtrl.text),
    };

    if (_type == CouponType.freeProduct) {
      updates['categoryId'] = _selectedCategoryId;
      updates['productId'] = _selectedProductId;
      updates['variantId'] = _selectedVariantId;
      updates['quantity'] = _parseInt(_quantityCtrl.text) ?? 1;
    }

    if (_type == CouponType.percentageDiscount) {
      updates['discountPercentage'] = _parseDouble(_discountPctCtrl.text);
      updates['minimumOrderAmount'] = _parseDouble(_minimumOrderCtrl.text);
      updates['maximumDiscountAmount'] = _parseDouble(_maximumDiscountCtrl.text);
      updates['discountAmount'] = null;
    }

    if (_type == CouponType.fixedAmountDiscount) {
      updates['discountAmount'] = _parseDouble(_discountAmountCtrl.text);
      updates['minimumOrderAmount'] = _parseDouble(_minimumOrderCtrl.text);
      updates['maximumDiscountAmount'] = null;
      updates['discountPercentage'] = null;
    }

    setState(() => _isSaving = true);
    try {
      await ref.read(couponRepositoryProvider).updateCoupon(
            businessId: widget.businessId,
            couponId: widget.coupon.id,
            updates: updates,
          );
      if (!mounted) return;
      widget.onUpdated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Coupon updated successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: AppColors.bgDark,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Update Coupon',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textOnDark),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _section(0, '1. Basics', _buildBasics()),
            _section(1, '2. Reward', _buildReward()),
            _section(2, '3. Validity & Points', _buildValidity()),
            _section(3, '4. Limits & Placement', _buildLimits()),
            _section(4, '5. Terms & Save', _buildTermsAndSave()),
          ],
        ),
      ),
    );
  }

  Widget _section(int index, String title, Widget body) {
    final isOpen = _expanded.contains(index);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            trailing: Icon(
              isOpen ? Icons.expand_less_rounded : Icons.expand_more_rounded,
              color: AppColors.textOnDark,
            ),
            onTap: () {
              setState(() {
                if (isOpen) {
                  _expanded.remove(index);
                } else {
                  _expanded.add(index);
                }
              });
            },
          ),
          if (isOpen) Padding(padding: const EdgeInsets.all(14), child: body),
        ],
      ),
    );
  }

  Widget _buildBasics() {
    return Column(
      children: [
        _input(_titleCtrl, 'Title *'),
        const SizedBox(height: 10),
        _input(_descriptionCtrl, 'Description', maxLines: 3),
        const SizedBox(height: 10),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Promotional Photo (Optional)',
            style: TextStyle(color: AppColors.textSubDark, fontSize: 13),
          ),
        ),
        const SizedBox(height: 8),
        _ImagePicker(
          isUploadingImage: _isUploadingImage,
          uploadedImageUrl: _uploadedImageUrl,
          onPick: _pickAndUploadImage,
          onRemove: () => setState(() => _uploadedImageUrl = null),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<CouponStatus>(
          initialValue: _status,
          dropdownColor: AppColors.cardDark,
          decoration: _decoration('Status'),
          items: CouponStatus.values
              .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.displayName),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _status = v ?? _status),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<CouponVisibility>(
          initialValue: _visibility,
          dropdownColor: AppColors.cardDark,
          decoration: _decoration('Visibility'),
          items: CouponVisibility.values
              .map((v) => DropdownMenuItem(
                    value: v,
                    child: Text(v.displayName),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _visibility = v ?? _visibility),
        ),
      ],
    );
  }

  Widget _buildReward() {
    return Column(
      children: [
        DropdownButtonFormField<CouponType>(
          initialValue: _type,
          dropdownColor: AppColors.cardDark,
          decoration: _decoration('Type'),
          items: CouponType.values
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t.displayName),
                  ))
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() => _type = v);
            _loadLookups();
          },
        ),
        const SizedBox(height: 10),
        if (_type == CouponType.freeProduct) ...[
          DropdownButtonFormField<int>(
            initialValue: _selectedCategoryId,
            dropdownColor: AppColors.cardDark,
            decoration: _decoration(
              _loadingCategories ? 'Category (loading...)' : 'Category',
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedCategoryId = v);
              _loadProducts(v);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _selectedProductId,
            dropdownColor: AppColors.cardDark,
            decoration: _decoration(
              _loadingProducts ? 'Product (loading...)' : 'Product',
            ),
            items: _products
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (v) {
              if (v == null) return;
              setState(() => _selectedProductId = v);
              _loadVariants(v);
            },
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<int>(
            initialValue: _selectedVariantId,
            dropdownColor: AppColors.cardDark,
            decoration: _decoration(
              _loadingVariants ? 'Variant (loading...)' : 'Variant (optional)',
            ),
            items: _variants
                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedVariantId = v),
          ),
          const SizedBox(height: 10),
          _input(_quantityCtrl, 'Quantity', keyboard: TextInputType.number),
        ],
        if (_type == CouponType.percentageDiscount) ...[
          _input(
            _discountPctCtrl,
            'Discount Percentage',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          _input(
            _minimumOrderCtrl,
            'Minimum Order Amount',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          _input(
            _maximumDiscountCtrl,
            'Maximum Discount Amount',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
        if (_type == CouponType.fixedAmountDiscount) ...[
          _input(
            _discountAmountCtrl,
            'Discount Amount',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 10),
          _input(
            _minimumOrderCtrl,
            'Minimum Order Amount',
            keyboard: const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ],
    );
  }

  Widget _buildValidity() {
    final f = DateFormat('MMM d, yyyy');
    return Column(
      children: [
        _input(_pointsCtrl, 'Points Cost *', keyboard: TextInputType.number),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(isStart: true),
                child: Text('Start: ${f.format(_startDate)}'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _pickDate(isStart: false),
                child: Text('End: ${f.format(_endDate)}'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLimits() {
    return Column(
      children: [
        _input(
          _totalLimitCtrl,
          'Total Redemption Limit',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _input(
          _perCustomerLimitCtrl,
          'Per Customer Redemption Limit',
          keyboard: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _input(_sortOrderCtrl, 'Sort Order', keyboard: TextInputType.number),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          value: _isFeatured,
          onChanged: (v) => setState(() => _isFeatured = v),
          title: const Text(
            'Featured Coupon',
            style: TextStyle(color: AppColors.textOnDark),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildTermsAndSave() {
    return Column(
      children: [
        _input(_termsCtrl, 'Terms & Conditions', maxLines: 4),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _submit,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(_isSaving ? 'Updating...' : 'Update Coupon'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMutedDark),
        filled: true,
        fillColor: AppColors.elevDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  Widget _input(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textOnDark),
      maxLines: maxLines,
      keyboardType: keyboard,
      decoration: _decoration(label),
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({
    required this.isUploadingImage,
    required this.uploadedImageUrl,
    required this.onPick,
    required this.onRemove,
  });

  final bool isUploadingImage;
  final String? uploadedImageUrl;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (isUploadingImage) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.elevDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              'Uploading...',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (uploadedImageUrl != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              uploadedImageUrl!,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _emptyState(),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(onTap: onPick, child: _emptyState());
  }

  Widget _emptyState() {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.elevDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: AppColors.textMutedDark,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Tap to upload photo',
            style: TextStyle(color: AppColors.textMutedDark, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
