import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StaffRolePill extends StatelessWidget {
  const StaffRolePill({super.key, required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primaryLight,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
