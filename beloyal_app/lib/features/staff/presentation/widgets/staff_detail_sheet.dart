import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/staff_member.dart';
import 'package:intl/intl.dart';
import './staff_status_badge.dart';
import './staff_role_pill.dart';

class StaffDetailSheet extends StatelessWidget {
  const StaffDetailSheet({super.key, required this.member});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: const Border(top: BorderSide(color: AppColors.glassBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              member.initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            member.fullName,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            member.email ?? 'No email provided',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
          ),
          const SizedBox(height: 24),

          // Detail cards
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              children: [
                _buildRow(
                  'Status',
                  StaffStatusBadge(status: member.memberStatus),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                _buildRow('Role', StaffRolePill(role: member.role)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                _buildRow(
                  'Hire Date',
                  Text(
                    member.hireDate != null
                        ? DateFormat('MMMM d, yyyy').format(member.hireDate!)
                        : 'Not provided',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),
                _buildRow(
                  'Last Login',
                  Text(
                    member.lastLogin != null
                        ? DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(member.lastLogin!)
                        : 'Never logged in',
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Disabled activity button
          SizedBox(
            width: double.infinity,
            child: Tooltip(
              message: 'Coming soon',
              child: OutlinedButton.icon(
                onPressed: null, // Disabled
                icon: const Icon(Icons.analytics_rounded),
                label: const Text('View Activity (Coming Soon)'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledForegroundColor: AppColors.textMuted.withValues(
                    alpha: 0.5,
                  ),
                  side: BorderSide(
                    color: AppColors.glassBorder.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, Widget child) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        child,
      ],
    );
  }
}
