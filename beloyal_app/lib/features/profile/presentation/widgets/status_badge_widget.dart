import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Color-coded badge for business status values.
class StatusBadgeWidget extends StatelessWidget {
  const StatusBadgeWidget({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final cfg = _resolve(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cfg.color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: cfg.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            cfg.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cfg.color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _resolve(String? status) {
    switch (status?.toUpperCase()) {
      case 'ACTIVE':
        return _StatusConfig('Active', AppColors.secondary);
      case 'SUSPENDED':
      case 'INACTIVE':
        return _StatusConfig('Suspended', AppColors.warning);
      case 'CLOSED':
        return _StatusConfig('Closed', AppColors.error);
      case 'REJECTED':
        return _StatusConfig('Rejected', AppColors.error);
      case 'PENDING_APPROVAL':
        return _StatusConfig('Pending Review', const Color(0xFFF97316));
      default:
        return _StatusConfig(status ?? 'Unknown', AppColors.textMuted);
    }
  }
}

class _StatusConfig {
  const _StatusConfig(this.label, this.color);
  final String label;
  final Color color;
}
