import 'package:flutter/material.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/customer_ui/domain/models/customer_ui_models.dart';

class CustomerMenuItemDetailSheet {
  const CustomerMenuItemDetailSheet._();

  static void show(
    BuildContext context,
    CustomerMenuItem item,
    List<Color> accentColors,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => _SheetBody(
          item: item,
          accentColors: accentColors,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.item,
    required this.accentColors,
    required this.scrollController,
  });

  final CustomerMenuItem item;
  final List<Color> accentColors;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final hasEarnedPoints = item.variants.any(
      (v) => v.earnedPoints != null && v.earnedPoints! > 0,
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPad),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── Item image / emoji hero ─────────────────────────────────────
          _buildItemHero(),
          const SizedBox(height: 16),
          // ── Name & metadata row ─────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: AppTypography.dmSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ),
                        if (item.isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFB8860B), AppColors.gold],
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  size: 10,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Popular',
                                  style: AppTypography.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.menuCategory,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: item.isAvailable
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.textMutedDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.isAvailable ? 'Available' : 'Unavailable',
                  style: AppTypography.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.isAvailable
                        ? AppColors.success
                        : AppColors.textMutedDark,
                  ),
                ),
              ),
            ],
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Description',
              style: AppTypography.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMutedDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.description,
              style: AppTypography.dmSans(
                fontSize: 14,
                color: AppColors.textOnDark,
                height: 1.5,
              ),
            ),
          ],
          // ── Unit label ──────────────────────────────────────────────────
          if (item.unit.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.straighten_rounded,
                  size: 14,
                  color: AppColors.textMutedDark,
                ),
                const SizedBox(width: 6),
                Text(
                  'Unit: ${item.unit}',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Options & Pricing',
            style: AppTypography.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textMutedDark,
            ),
          ),
          const SizedBox(height: 10),
          ...item.variants.map((v) {
            final earnLabel = v.earnedPoints != null && v.earnedPoints! > 0
                ? '+${v.earnedPoints} pts'
                : null;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: v.isDefault
                    ? accentColors.first.withValues(alpha: 0.08)
                    : AppColors.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: v.isDefault
                      ? accentColors.first.withValues(alpha: 0.3)
                      : AppColors.glassBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (v.isDefault) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColors.first.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Default',
                            style: AppTypography.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: accentColors.first,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          v.name,
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            fontWeight: v.isDefault
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: AppColors.textOnDark,
                          ),
                        ),
                      ),
                      if (earnLabel != null) ...[
                        Text(
                          earnLabel,
                          style: AppTypography.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Text(
                        v.formattedPrice,
                        style: AppTypography.dmMono(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                  if (v.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      v.description,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
          if (item.pointsLabel.isNotEmpty && !hasEarnedPoints) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.pointsLabel,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemHero() {
    if (item.imageUrl?.isNotEmpty == true) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: Image.network(
            item.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildEmojiHero(),
          ),
        ),
      );
    }
    return _buildEmojiHero();
  }

  Widget _buildEmojiHero() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColors.first.withValues(alpha: 0.6),
            accentColors.last.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Text(item.emoji, style: const TextStyle(fontSize: 52)),
      ),
    );
  }
}
