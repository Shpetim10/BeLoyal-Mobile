import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/staff_membership.dart';
import 'readonly_field_row.dart';
import 'section_card_widget.dart';
import 'status_badge_widget.dart';
import '../../../auth/presentation/widgets/status_banner.dart';

/// Displays the staff's membership context (restaurant, status, hire date).
class MembershipCard extends StatelessWidget {
  const MembershipCard({super.key, required this.membership});

  final StaffMembership membership;

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: 'Restaurant Access',
      icon: Icons.badge_rounded,
      children: [
        if (membership.memberStatus.backendValue != 'ACTIVE') ...[
          StatusBanner(
            message:
                'Your staff access is inactive. You may be unable to use staff features.',
            type: StatusBannerType.warning,
          ),
          const SizedBox(height: 16),
        ],
        ReadonlyFieldRow(
          label: 'Restaurant',
          value: membership.businessName,
          icon: Icons.store_rounded,
          showHelper: false,
        ),
        const SizedBox(height: 16),

        // Custom row for Status Badge
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadgeWidget(
                    status: membership.memberStatus.backendValue,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        const SizedBox(height: 16),
        ReadonlyFieldRow(
          label: 'Hire Date',
          value: membership.hireDate != null
              ? DateFormat.yMMMd().format(membership.hireDate!)
              : '—',
          icon: Icons.calendar_today_rounded,
          showHelper: false,
        ),
        if (membership.lastLogin != null) ...[
          const SizedBox(height: 16),
          ReadonlyFieldRow(
            label: 'Last Login',
            value: DateFormat.yMMMd().add_jm().format(
              membership.lastLogin!.toLocal(),
            ),
            icon: Icons.login_rounded,
            showHelper: false,
          ),
        ],

        const SizedBox(height: 20),
        const Text(
          'Your admin manages your restaurant access and activation status.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
