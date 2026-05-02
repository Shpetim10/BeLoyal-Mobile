import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_lookup_models.dart';
import 'coupon_status_chip.dart';

class CouponPreviewCard extends StatelessWidget {
  const CouponPreviewCard({
    super.key,
    required this.type,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.pointsCost,
    required this.visibility,
    required this.publishImmediately,
    required this.startDate,
    required this.endDate,
    // FREE_PRODUCT
    this.selectedCategory,
    this.selectedProduct,
    this.selectedVariant,
    this.quantity,
    // DISCOUNT
    this.discountPercentage,
    this.discountAmount,
    this.minimumOrderAmount,
    this.maximumDiscountAmount,
    this.currency,
  });

  final CouponType type;
  final String title;
  final String description;
  final String? imageUrl;
  final String pointsCost;
  final CouponVisibility visibility;
  final bool publishImmediately;
  final DateTime? startDate;
  final DateTime? endDate;

  final CategoryLookup? selectedCategory;
  final ProductLookup? selectedProduct;
  final VariantLookup? selectedVariant;
  final String? quantity;

  final String? discountPercentage;
  final String? discountAmount;
  final String? minimumOrderAmount;
  final String? maximumDiscountAmount;
  final CouponCurrency? currency;

  String get _currencyLabel => currency?.symbol ?? '';

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final status = publishImmediately
        ? CouponStatus.active
        : CouponStatus.draft;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorderStrong),
        boxShadow: [
          BoxShadow(
            color: type.color.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type + status row
                Row(
                  children: [
                    CouponTypeBadge(type: type),
                    const SizedBox(width: 8),
                    CouponStatusChip(status: status),
                    const SizedBox(width: 8),
                    Icon(visibility.icon, size: 14, color: visibility.color),
                    const SizedBox(width: 4),
                    Text(
                      visibility.displayName,
                      style: TextStyle(
                        color: visibility.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Title
                Text(
                  title.isEmpty ? 'Coupon Title' : title,
                  style: const TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                // Description
                Text(
                  description.isEmpty
                      ? 'Description will be generated automatically.'
                      : description,
                  style: TextStyle(
                    color: description.isEmpty
                        ? AppColors.textMuted
                        : AppColors.textSubDark,
                    fontSize: 13,
                    fontStyle: description.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.glassBorder),
                const SizedBox(height: 10),

                // Points cost
                Row(
                  children: [
                    const Icon(
                      Icons.monetization_on,
                      size: 18,
                      color: AppColors.gold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      pointsCost.isEmpty ? '— pts' : '$pointsCost pts',
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'DM Mono',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Type-specific details
                if (type == CouponType.freeProduct)
                  _buildFreeProductSection()
                else
                  _buildDiscountSection(),

                const SizedBox(height: 10),

                // Date range
                if (startDate != null && endDate != null)
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    '${dateFormat.format(startDate!)} – ${dateFormat.format(endDate!)}',
                  )
                else
                  _buildInfoRow(
                    Icons.calendar_today_outlined,
                    'Dates not set',
                    muted: true,
                  ),

                if (type == CouponType.freeProduct &&
                    (imageUrl == null || imageUrl!.isEmpty))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 12,
                          color: AppColors.textMutedDark,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Product photo will be used if no coupon photo is uploaded.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: AppColors.elevDark,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type.icon, size: 40, color: type.color.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            type == CouponType.freeProduct
                ? 'Product photo will be used'
                : 'No image',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeProductSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selectedProduct != null) ...[
          _buildInfoRow(Icons.category_outlined, selectedCategory?.name ?? '—'),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.shopping_bag_outlined,
            selectedProduct!.name +
                (selectedVariant != null ? ' · ${selectedVariant!.name}' : ''),
          ),
          if (quantity != null && quantity!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _buildInfoRow(Icons.numbers, 'Qty: $quantity'),
            ),
        ] else
          _buildInfoRow(
            Icons.shopping_bag_outlined,
            'No product selected',
            muted: true,
          ),
      ],
    );
  }

  Widget _buildDiscountSection() {
    final hasPct = discountPercentage != null && discountPercentage!.isNotEmpty;
    final hasAmt = discountAmount != null && discountAmount!.isNotEmpty;
    final hasMin = minimumOrderAmount != null && minimumOrderAmount!.isNotEmpty;
    final hasMax =
        type == CouponType.percentageDiscount &&
        maximumDiscountAmount != null &&
        maximumDiscountAmount!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (type == CouponType.percentageDiscount && hasPct)
          _buildInfoRow(Icons.percent, '$discountPercentage% off'),
        if (type == CouponType.fixedAmountDiscount && hasAmt)
          _buildInfoRow(
            Icons.discount_outlined,
            '$_currencyLabel $discountAmount off'.trim(),
          ),
        if (hasMin)
          _buildInfoRow(
            Icons.shopping_cart_outlined,
            'Min order: $_currencyLabel $minimumOrderAmount'.trim(),
          ),
        if (hasMax)
          _buildInfoRow(
            Icons.money_off,
            'Max discount: $_currencyLabel $maximumDiscountAmount'.trim(),
          ),
        if (!hasPct && !hasAmt)
          _buildInfoRow(
            Icons.discount_outlined,
            'Discount not set',
            muted: true,
          ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {bool muted = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: muted ? AppColors.textMutedDark : AppColors.textSubDark,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: muted ? AppColors.textMuted : AppColors.textSubDark,
              fontSize: 13,
              fontStyle: muted ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}
