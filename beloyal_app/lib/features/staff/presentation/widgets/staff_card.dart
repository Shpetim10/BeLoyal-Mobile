import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/staff_member.dart';
import './staff_status_badge.dart';
import './staff_role_pill.dart';
import 'package:intl/intl.dart';

class StaffCard extends StatelessWidget {
  const StaffCard({
    super.key,
    required this.member,
    required this.onTap,
    required this.onDeactivate,
    required this.onReactivate,
    required this.onResendInvite,
    required this.onCancelInvite,
  });

  final StaffMember member;
  final VoidCallback onTap;
  final VoidCallback onDeactivate;
  final VoidCallback onReactivate;
  final VoidCallback onResendInvite;
  final VoidCallback onCancelInvite;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: AppColors.primary.withValues(alpha: 0.1),
          splashColor: AppColors.primary.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.fullName,
                              style: const TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          StaffRolePill(role: member.role),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email ?? '—',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StaffStatusBadge(status: member.memberStatus),
                          const Spacer(),
                          Text(
                            member.lastLogin != null
                                ? 'Last login: ${DateFormat('MMM d, yyyy').format(member.lastLogin!)}'
                                : 'Last login: —',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Trailing actions dropdown menu
                const SizedBox(width: 8),
                _buildActionMenu(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      onSelected: (val) {
        if (val == 0) onDeactivate();
        if (val == 1) onReactivate();
        if (val == 2) onResendInvite();
        if (val == 3) onCancelInvite();
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<int>>[];
        if (member.memberStatus == MemberStatus.active) {
          items.add(
            _buildMenuItem(
              0,
              'Deactivate',
              Icons.power_settings_new_rounded,
              AppColors.error,
            ),
          );
        } else if (member.memberStatus == MemberStatus.inactive) {
          items.add(
            _buildMenuItem(
              1,
              'Reactivate',
              Icons.play_arrow_rounded,
              AppColors.secondary,
            ),
          );
        } else if (member.memberStatus == MemberStatus.invited) {
          items.add(
            _buildMenuItem(
              2,
              'Resend Invite',
              Icons.send_rounded,
              AppColors.primary,
            ),
          );
          items.add(
            _buildMenuItem(
              3,
              'Cancel Invite',
              Icons.cancel_rounded,
              AppColors.error,
            ),
          );
        }
        return items;
      },
    );
  }

  PopupMenuItem<int> _buildMenuItem(
    int val,
    String label,
    IconData icon,
    Color color,
  ) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
