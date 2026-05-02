import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/coupon_enums.dart';
import '../../data/models/coupon_summary.dart';
import 'coupon_status_chip.dart';

class CouponCard extends StatelessWidget {
  const CouponCard({
    super.key,
    required this.coupon,
    required this.onTap,
    required this.onStatusChange,
    required this.onVisibilityChange,
    required this.onDelete,
    required this.onArchive,
  });

  final CouponSummary coupon;
  final VoidCallback onTap;
  final void Function(CouponStatus) onStatusChange;
  final void Function(CouponVisibility) onVisibilityChange;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image + type row
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: coupon.imageUrl != null
                  ? Image.network(
                      coupon.imageUrl!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CouponTypeBadge(type: coupon.type, small: true),
                      const SizedBox(width: 8),
                      CouponStatusChip(status: coupon.status, small: true),
                      if (coupon.isFeatured) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.star, size: 14, color: AppColors.gold),
                      ],
                      const Spacer(),
                      _ContextMenu(
                        coupon: coupon,
                        onStatusChange: onStatusChange,
                        onVisibilityChange: onVisibilityChange,
                        onDelete: onDelete,
                        onArchive: onArchive,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on_outlined,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${coupon.pointsCost} pts',
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'DM Mono',
                        ),
                      ),
                      const Spacer(),
                      if (coupon.hasRedemptionLimit)
                        Text(
                          '${coupon.totalRedemptions}/${coupon.totalRedemptionLimit} used',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          '${coupon.totalRedemptions} used',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: AppColors.textMutedDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dateFormat.format(coupon.startDate)} – ${dateFormat.format(coupon.endDate)}',
                        style: const TextStyle(
                          color: AppColors.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 80,
      width: double.infinity,
      color: AppColors.elevDark,
      child: Icon(
        coupon.type.icon,
        size: 32,
        color: coupon.type.color.withValues(alpha: 0.5),
      ),
    );
  }
}

class _ContextMenu extends StatelessWidget {
  const _ContextMenu({
    required this.coupon,
    required this.onStatusChange,
    required this.onVisibilityChange,
    required this.onDelete,
    required this.onArchive,
  });

  final CouponSummary coupon;
  final void Function(CouponStatus) onStatusChange;
  final void Function(CouponVisibility) onVisibilityChange;
  final VoidCallback onDelete;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final transitions = coupon.status.allowedTransitions;
    final nextVisibility = coupon.visibility == CouponVisibility.public
        ? CouponVisibility.hidden
        : CouponVisibility.public;
    final visibilityActionLabel = nextVisibility == CouponVisibility.hidden
        ? 'Hide'
        : 'Show';

    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_vert,
        size: 18,
        color: AppColors.textMutedDark,
      ),
      color: AppColors.elevDark,
      itemBuilder: (_) => [
        if (transitions.contains(CouponStatus.active))
          const PopupMenuItem(value: 'activate', child: Text('Activate')),
        if (transitions.contains(CouponStatus.paused))
          const PopupMenuItem(value: 'pause', child: Text('Pause')),
        if (transitions.contains(CouponStatus.draft))
          const PopupMenuItem(value: 'restore', child: Text('Restore to Draft')),
        if (transitions.contains(CouponStatus.archived))
          const PopupMenuItem(value: 'archive', child: Text('Archive')),
        PopupMenuItem(
          value: 'toggleVisibility',
          child: Text(visibilityActionLabel),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'delete',
          child: Text('Delete', style: TextStyle(color: AppColors.error)),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'activate':
            onStatusChange(CouponStatus.active);
            return;
          case 'pause':
            onStatusChange(CouponStatus.paused);
            return;
          case 'restore':
            onStatusChange(CouponStatus.draft);
            return;
          case 'archive':
            onArchive();
            return;
          case 'toggleVisibility':
            onVisibilityChange(nextVisibility);
            return;
          case 'delete':
            onDelete();
            return;
        }
      },
    );
  }
}
