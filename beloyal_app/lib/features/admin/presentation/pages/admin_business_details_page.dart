import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/admin_business_dtos.dart';
import '../controllers/admin_business_controller.dart';

class AdminBusinessDetailsPage extends ConsumerStatefulWidget {
  const AdminBusinessDetailsPage({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<AdminBusinessDetailsPage> createState() =>
      _AdminBusinessDetailsPageState();
}

class _AdminBusinessDetailsPageState
    extends ConsumerState<AdminBusinessDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final businessAsync =
        ref.watch(adminBusinessDetailsProvider(widget.businessId));
    final lifecycleState = ref.watch(adminBusinessLifecycleProvider);

    ref.listen(adminBusinessLifecycleProvider, (previous, next) {
      if (!context.mounted) return;
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.hasValue && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Page refreshed with latest data'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          businessAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, _) => _buildErrorState(err.toString()),
            data: (business) => _buildFancyDetails(context, business),
          ),
          if (lifecycleState.isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFancyDetails(BuildContext context, BusinessDetailsDto business) {
    final hasLogo =
        business.logoPath != null && business.logoPath!.isNotEmpty;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Hero AppBar ──────────────────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: AppColors.surfaceDark,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (hasLogo)
                  Image.network(business.logoPath!, fit: BoxFit.cover)
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryDark,
                          AppColors.bgDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 80,
                      color: AppColors.textMuted,
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.4),
                        Colors.transparent,
                        AppColors.bgDark,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (business.businessType.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Text(
                            business.businessType,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Body Content ─────────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildStatusSection(business),
              const SizedBox(height: 20),

              // ── Admin Action Buttons ────────────────────────────────────────
              _AdminActionsBar(
                businessId: widget.businessId,
                businessName: business.businessName,
                status: business.businessStatus,
              ).animate().fadeIn(duration: 400.ms).slideY(
                    begin: 0.08,
                    end: 0,
                    curve: Curves.easeOut,
                  ),
              const SizedBox(height: 20),

              _buildSectionCard(
                'About',
                Icons.info_outline_rounded,
                [
                  if (business.businessDescription.isNotEmpty)
                    Text(
                      business.businessDescription,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    )
                  else
                    const Text(
                      'No description provided.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                'Contact & Location',
                Icons.pin_drop_outlined,
                [
                  _buildInfoRow(
                    Icons.phone_rounded,
                    'Phone',
                    business.businessPhoneNumber,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Address',
                    '${business.address}\n${business.city}, ${business.country}',
                  ),
                  if (business.vatId != null &&
                      business.vatId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.receipt_long_rounded,
                      'VAT ID',
                      business.vatId!,
                    ),
                  ],
                  if (business.currencyCode != null &&
                      business.currencyCode!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.payments_rounded,
                      'Currency',
                      business.currencyCode!,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _buildSectionCard(
                'Team Members',
                Icons.people_outline_rounded,
                [
                  if (business.businessMembers.isEmpty)
                    const Text(
                      'No team members found.',
                      style: TextStyle(color: AppColors.textMuted),
                    )
                  else
                    ...business.businessMembers.map(
                      (m) => _buildMemberTile(m),
                    ),
                ],
              ),
              const SizedBox(height: 80),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSection(BusinessDetailsDto business) {
    Color statColor = AppColors.textMuted;
    if (business.businessStatus == 'ACTIVE') statColor = AppColors.secondary;
    if (business.businessStatus == 'PENDING') statColor = AppColors.warning;
    if (business.businessStatus == 'REJECTED') statColor = AppColors.error;
    if (business.businessStatus == 'INACTIVE') statColor = AppColors.warning;
    if (business.businessStatus == 'BANNED') statColor = AppColors.error;

    final DateFormat formatter = DateFormat('MMM d, yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  business.businessStatus,
                  style: TextStyle(
                    color: statColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (business.rejectionReason != null &&
              business.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: const Border(
                  left: BorderSide(color: AppColors.error, width: 4),
                ),
              ),
              child: Text(
                'Reason: ${business.rejectionReason}',
                style: const TextStyle(
                  color: AppColors.errorLight,
                  fontSize: 13,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDateColumn(
                'Submitted',
                business.submittedAt != null
                    ? formatter.format(business.submittedAt!)
                    : 'N/A',
              ),
              _buildDateColumn(
                'Reviewed',
                business.reviewedAt != null
                    ? formatter.format(business.reviewedAt!)
                    : 'Pending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(String label, String date) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textMuted, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberTile(BusinessMemberDetailsDto member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withValues(alpha: 0.2),
            foregroundColor: AppColors.primaryLight,
            child: Text(
              member.firstName.isNotEmpty
                  ? member.firstName[0].toUpperCase()
                  : '?',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  member.email,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Text(
              member.role.replaceAll('ROLE_', ''),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Oops!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  ref.refresh(adminBusinessDetailsProvider(widget.businessId)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Admin Action Buttons ───────────────────────────────────────────────────────

class _AdminActionsBar extends ConsumerWidget {
  const _AdminActionsBar({
    required this.businessId,
    required this.businessName,
    required this.status,
  });

  final int businessId;
  final String businessName;
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = status.toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorderStrong),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Admin Actions',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Reactivate — shown when INACTIVE or BANNED
              if (s == 'INACTIVE' || s == 'BANNED')
                _ActionButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Reactivate',
                  color: AppColors.success,
                  onTap: () => _confirmReactivate(context, ref),
                ),

              // Suspend — shown when ACTIVE
              if (s == 'ACTIVE')
                _ActionButton(
                  icon: Icons.pause_circle_rounded,
                  label: 'Suspend',
                  color: AppColors.warning,
                  onTap: () => _showReasonDialog(
                    context,
                    ref,
                    title: 'Suspend Business',
                    hint: 'Reason for suspension',
                    icon: Icons.pause_circle_rounded,
                    color: AppColors.warning,
                    onConfirm: (reason) => ref
                        .read(adminBusinessLifecycleProvider.notifier)
                        .suspend(businessId, reason),
                  ),
                ),

              // Ban — shown when ACTIVE or INACTIVE
              if (s == 'ACTIVE' || s == 'INACTIVE')
                _ActionButton(
                  icon: Icons.block_rounded,
                  label: 'Ban',
                  color: AppColors.error,
                  onTap: () => _showReasonDialog(
                    context,
                    ref,
                    title: 'Ban Business',
                    hint: 'Reason for permanent ban',
                    icon: Icons.block_rounded,
                    color: AppColors.error,
                    onConfirm: (reason) => ref
                        .read(adminBusinessLifecycleProvider.notifier)
                        .ban(businessId, reason),
                  ),
                ),

              // Delete — always shown
              _ActionButton(
                icon: Icons.delete_forever_rounded,
                label: 'Delete',
                color: const Color(0xFF7F1D1D),
                onTap: () => _confirmDelete(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReactivate(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Reactivate Business',
        message:
            'Are you sure you want to reactivate "$businessName"? They will be able to operate again.',
        confirmLabel: 'Reactivate',
        confirmColor: AppColors.success,
        icon: Icons.check_circle_rounded,
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(adminBusinessLifecycleProvider.notifier)
          .reactivate(businessId);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: 'Delete Business',
        message:
            'This will PERMANENTLY delete "$businessName" and ALL associated data including loyalty accounts, transactions, and coupons. This cannot be undone.',
        confirmLabel: 'Delete Forever',
        confirmColor: AppColors.error,
        icon: Icons.delete_forever_rounded,
        isDangerous: true,
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(adminBusinessLifecycleProvider.notifier)
          .delete(businessId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Business deleted • Refreshing list...'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            ref.invalidate(adminAllBusinessesProvider);
            context.pop();
          }
        });
      }
    }
  }

  Future<void> _showReasonDialog(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String hint,
    required IconData icon,
    required Color color,
    required Future<void> Function(String reason) onConfirm,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReasonDialog(
        title: title,
        hint: hint,
        icon: icon,
        color: color,
        controller: controller,
      ),
    );
    if (confirmed == true && context.mounted) {
      final reason = controller.text.trim();
      if (reason.isEmpty) return;
      await onConfirm(reason);
    }
    controller.dispose();
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.color.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, color: widget.color, size: 16),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.icon,
    this.isDangerous = false,
  });
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final IconData icon;
  final bool isDangerous;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: confirmColor, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            confirmLabel,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _ReasonDialog extends StatelessWidget {
  const _ReasonDialog({
    required this.title,
    required this.hint,
    required this.icon,
    required this.color,
    required this.controller,
  });
  final String title;
  final String hint;
  final IconData icon;
  final Color color;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Please provide a reason. This will be included in the email notification sent to the business.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.bgDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.4)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: color.withValues(alpha: 0.25)),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Confirm',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
