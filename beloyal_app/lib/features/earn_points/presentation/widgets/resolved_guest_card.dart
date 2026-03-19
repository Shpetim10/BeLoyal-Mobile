import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/resolved_guest.dart';

/// Compact card showing a resolved guest with avatar, name, loyalty ID,
/// and a remove button. Used in the guest list during scanning.
class ResolvedGuestCard extends StatelessWidget {
  const ResolvedGuestCard({
    super.key,
    required this.guest,
    required this.onRemove,
    this.showRemove = true,
    this.compact = false,
  });

  final ResolvedGuest guest;
  final VoidCallback onRemove;
  final bool showRemove;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: compact
          ? const EdgeInsets.only(bottom: 6)
          : const EdgeInsets.only(bottom: 10),
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Avatar ──
          Container(
            width: compact ? 36 : 44,
            height: compact ? 36 : 44,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              guest.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 13 : 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: compact ? 10 : 14),

          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guest.fullName,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: compact ? 13 : 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
              ],
            ),
          ),

          // ── Points badge ──
          if (!compact) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${guest.currentPoints} pts',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // ── Remove button ──
          if (showRemove)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.error,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
