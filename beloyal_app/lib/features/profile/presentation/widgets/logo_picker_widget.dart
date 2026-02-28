import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';

/// Logo picker widget with square preview, upload/remove options.
/// Mirrors the avatar picker in ProfilePage but with a square/rounded shape.
class LogoPickerWidget extends StatelessWidget {
  const LogoPickerWidget({
    super.key,
    this.logoUrl,
    this.pendingLogo,
    this.isUploading = false,
    required this.onPick,
    required this.onRemove,
    this.businessName,
  });

  final String? logoUrl;
  final XFile? pendingLogo;
  final bool isUploading;
  final Future<void> Function(XFile file) onPick;
  final VoidCallback onRemove;
  final String? businessName;

  bool get _hasLogo =>
      pendingLogo != null || (logoUrl != null && logoUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Stack(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: isUploading
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : AppColors.glassBorder,
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _buildImageOrContent(),
            ),
          ),

          // Upload progress overlay
          if (isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black.withValues(alpha: 0.45),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  ),
                ),
              ),
            ),

          // Camera badge
          if (!isUploading)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageOrContent() {
    if (pendingLogo != null) {
      return Image.file(
        File(pendingLogo!.path),
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackContent(),
      );
    }

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      return Image.network(
        logoUrl!,
        fit: BoxFit.cover,
        errorBuilder: (ctx, err, stack) => _buildFallbackContent(),
      );
    }

    return _buildFallbackContent();
  }

  Widget _buildFallbackContent() {
    if (isUploading) return const SizedBox.shrink();

    final letter = businessName?.isNotEmpty == true
        ? businessName![0].toUpperCase()
        : null;

    if (letter != null) {
      return Center(
        child: Text(
          letter,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.store_rounded, size: 32, color: AppColors.primary),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Business Logo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(context, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  title: const Text('Take a photo'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage(context, ImageSource.camera);
                  },
                ),
                if (_hasLogo)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_rounded,
                        color: AppColors.error,
                      ),
                    ),
                    title: const Text(
                      'Remove logo',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      onRemove();
                    },
                  ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final ext = picked.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only JPG and PNG are allowed'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      await onPick(picked);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
