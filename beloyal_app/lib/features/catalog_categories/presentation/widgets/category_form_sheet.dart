import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../data/models/catalog_category.dart';
import '../controllers/catalog_category_controller.dart';

/// Create / Edit category bottom sheet form.
///
/// When [existingCategory] is null → Create mode.
/// When [existingCategory] is provided → Edit mode (form pre-filled).
///
/// Edit flow is fully wired to [CatalogCategoryController.updateCategory].
/// The endpoint on the backend will be plugged in when available.
class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    required this.businessId,
    this.existingCategory,
    required this.onSuccess,
  });

  final int businessId;
  final CatalogCategory? existingCategory;
  final VoidCallback onSuccess;

  bool get isEditMode => existingCategory != null;

  static Future<void> show(
    BuildContext context, {
    required int businessId,
    CatalogCategory? existingCategory,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryFormSheet(
        businessId: businessId,
        existingCategory: existingCategory,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _isSubmitting = false;
  String? _inlineError;

  // ── Validation ────────────────────────────────────────────────────────────
  static const int _maxName = 120;
  static const int _maxDesc = 300;

  @override
  void initState() {
    super.initState();
    _nameCtrl =
        TextEditingController(text: widget.existingCategory?.name ?? '');
    _descCtrl =
        TextEditingController(text: widget.existingCategory?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    final controller = ref.read(catalogCategoryControllerProvider.notifier);
    final businessId = widget.businessId;
    final name = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    CatalogCategory? result;

    if (widget.isEditMode) {
      result = await controller.updateCategory(
        businessId: businessId,
        categoryId: widget.existingCategory!.id,
        name: name,
        description: desc,
      );
    } else {
      result = await controller.createCategory(
        businessId: businessId,
        name: name,
        description: desc,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result != null) {
      Navigator.of(context).pop();
      widget.onSuccess();
      _showSuccessSnackbar(widget.isEditMode);
    } else {
      final errorMsg = ref.read(catalogCategoryControllerProvider).createError;
      setState(() => _inlineError = errorMsg ?? 'Something went wrong.');
    }
  }

  void _showSuccessSnackbar(bool isEdit) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.secondary, size: 20),
            const SizedBox(width: 10),
            Text(
              isEdit
                  ? 'Category updated successfully!'
                  : 'Category created successfully!',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
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
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),

              // ── Title ────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.isEditMode
                            ? Icons.edit_rounded
                            : Icons.add_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.isEditMode
                                ? 'Edit Category'
                                : 'New Category',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            widget.isEditMode
                                ? 'Update the category details below'
                                : 'Add a new category to your catalog',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        foregroundColor: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Form ─────────────────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      24, 0, 24, 16 + bottomPadding),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Inline error ────────────────────────────────────
                        if (_inlineError != null) ...[
                          _ErrorBanner(message: _inlineError!),
                          const SizedBox(height: 16),
                        ],

                        // ── Name ────────────────────────────────────────────
                        _FieldLabel('Category Name', required: true),
                        const SizedBox(height: 8),
                        ValueListenableBuilder(
                          valueListenable: _nameCtrl,
                          builder: (_, nameVal, __) {
                            return TextFormField(
                              controller: _nameCtrl,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(_maxName),
                              ],
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'e.g. Starters, Main Course…',
                                prefixIcon: const Icon(
                                  Icons.label_rounded,
                                  size: 20,
                                ),
                                suffixText:
                                    '${nameVal.text.length}/$_maxName',
                                suffixStyle: TextStyle(
                                  color:
                                      nameVal.text.length >= _maxName - 10
                                          ? AppColors.error
                                          : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Category name is required';
                                }
                                if (v.trim().length > _maxName) {
                                  return 'Max $_maxName characters';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // ── Description ──────────────────────────────────────
                        _FieldLabel('Description', required: false),
                        const SizedBox(height: 8),
                        ValueListenableBuilder(
                          valueListenable: _descCtrl,
                          builder: (_, descVal, __) {
                            return TextFormField(
                              controller: _descCtrl,
                              maxLines: 4,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(_maxDesc),
                              ],
                              textCapitalization:
                                  TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText:
                                    'Optional — describe this category…',
                                alignLabelWithHint: true,
                                suffixText:
                                    '${descVal.text.length}/$_maxDesc',
                                suffixStyle: TextStyle(
                                  color:
                                      descVal.text.length >= _maxDesc - 20
                                          ? AppColors.error
                                          : AppColors.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              validator: (v) {
                                if (v != null &&
                                    v.length > _maxDesc) {
                                  return 'Max $_maxDesc characters';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 28),

                        // ── Submit ───────────────────────────────────────────
                        _SubmitButton(
                          isEditMode: widget.isEditMode,
                          isSubmitting: _isSubmitting,
                          onTap: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ),
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

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {required this.required});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.isEditMode,
    required this.isSubmitting,
    required this.onTap,
  });

  final bool isEditMode;
  final bool isSubmitting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap != null
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [
                    AppColors.textMuted.withValues(alpha: 0.3),
                    AppColors.textMuted.withValues(alpha: 0.3),
                  ],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: isSubmitting
              ? const BesaLoader(size: 22, color: Colors.white)
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEditMode
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isEditMode ? 'Save Changes' : 'Create Category',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
