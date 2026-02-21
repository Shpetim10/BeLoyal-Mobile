import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/staff_member.dart';

class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge({super.key, required this.status});
  final MemberStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      MemberStatus.active => AppColors.secondary,
      MemberStatus.inactive => AppColors.textMuted,
      MemberStatus.invited => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
