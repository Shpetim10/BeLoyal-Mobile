import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/models/business_application.dart';
import 'controllers/applications_controller.dart';

class ApplicationDetailsPage extends ConsumerStatefulWidget {
  const ApplicationDetailsPage({super.key, required this.applicationId});

  final int applicationId;

  @override
  ConsumerState<ApplicationDetailsPage> createState() =>
      _ApplicationDetailsPageState();
}

class _ApplicationDetailsPageState
    extends ConsumerState<ApplicationDetailsPage> {
  bool _isProcessing = false;

  Future<void> _handleApprove(BusinessApplication app) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Approve this business?',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: const Text(
          'This will activate the business and grant the owner restaurant admin access.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnDark,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    final error = await ref
        .read(applicationsControllerProvider.notifier)
        .approve(app.id);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Business was approved')));
      context.pop(); // Navigate back to the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving Application: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _promptReject(BusinessApplication app) {
    final controller = TextEditingController();
    bool isError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (stCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Reject business',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This reason will be emailed to the business owner.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textOnDark),
                    onChanged: (val) {
                      if (isError && val.trim().isNotEmpty) {
                        setModalState(() => isError = false);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Rejection reason...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.bgDark,
                      errorText: isError
                          ? 'Rejection reason is required'
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMuted,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final reason = controller.text.trim();
                            if (reason.isEmpty) {
                              setModalState(() => isError = true);
                              return;
                            }
                            Navigator.pop(ctx);
                            await _handleReject(app, reason);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReject(BusinessApplication app, String reason) async {
    setState(() => _isProcessing = true);
    final error = await ref
        .read(applicationsControllerProvider.notifier)
        .reject(app.id, reason);

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Business was rejected')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting Application: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(applicationsControllerProvider);
    final app = state.value?.firstWhere(
      (element) => element.id == widget.applicationId,
      orElse: () => throw Exception('Application not found.'),
    );

    // If app becomes null (e.g., approved/removed from list) before redirect
    if (app == null) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: AppColors.textOnDark),
        ),
        body: const Center(
          child: Text(
            'Application not found.',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: SafeArea(
        child: Column(
          children: [
            // ── Breadcrumb AppBar ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark,
                border: Border(
                  bottom: BorderSide(color: AppColors.glassBorder),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textOnDark,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Business Applications',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      app.businessName,
                      style: const TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Body ──
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Tablet/Desktop can go Row, Mobile goes Column
                  final isWide = constraints.maxWidth > 800;

                  final mainContent = SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BusinessDetailsCard(app: app),
                        const SizedBox(height: 24),
                        _OwnerDetailsCard(owner: app.owner),
                      ],
                    ),
                  );

                  final actionsPanel = Container(
                    width: isWide ? 300 : double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      border: isWide
                          ? const Border(
                              left: BorderSide(color: AppColors.glassBorder),
                            )
                          : const Border(
                              top: BorderSide(color: AppColors.glassBorder),
                            ),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Review Actions',
                                style: TextStyle(
                                  color: AppColors.textOnDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _handleApprove(app),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.textOnDark,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Approve Application',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () => _promptReject(app),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.error,
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Reject Application',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: mainContent),
                        actionsPanel,
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Expanded(child: mainContent),
                      actionsPanel,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _BusinessDetailsCard extends StatelessWidget {
  const _BusinessDetailsCard({required this.app});
  final BusinessApplication app;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return _SectionCard(
      title: 'Application Overview',
      icon: Icons.business_rounded,
      children: [
        // Top branding row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Center(
                child: Text(
                  app.businessName.isNotEmpty ? app.businessName[0] : '?',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.businessName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'PENDING_APPROVAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Business Details',
          style: TextStyle(
            color: AppColors.textOnDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _DataRow(label: 'Type', value: app.businessType.displayName),
        _DataRow(label: 'Email', value: app.businessEmail),
        _DataRow(label: 'Phone', value: app.businessPhoneNumber ?? 'N/A'),
        _DataRow(
          label: 'Address',
          value:
              '${app.address ?? ''}${app.address != null ? ', ' : ''}${app.city}, ${app.country ?? ''}'
                  .trim(),
        ),
        _DataRow(label: 'VAT ID', value: app.vatId),
        _DataRow(label: 'Website', value: app.websiteUrl ?? 'N/A'),
        const SizedBox(height: 16),
        if (app.businessDescription?.isNotEmpty ?? false) ...[
          const Text(
            'Description',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            app.businessDescription!,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Divider(color: AppColors.glassBorder),
        const SizedBox(height: 16),
        _DataRow(label: 'Submitted ID', value: '#${app.id}'),
        _DataRow(
          label: 'Submitted At',
          value: app.submittedAt != null
              ? dateFormat.format(app.submittedAt!)
              : 'Unknown',
        ),
      ],
    );
  }
}

class _OwnerDetailsCard extends StatelessWidget {
  const _OwnerDetailsCard({required this.owner});
  final ApplicationOwner? owner;

  @override
  Widget build(BuildContext context) {
    if (owner == null) {
      return _SectionCard(
        title: 'Owner Details',
        icon: Icons.person_rounded,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Owner details were not provided or are unavailable at this stage.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return _SectionCard(
      title: 'Owner Details',
      icon: Icons.person_rounded,
      children: [
        _DataRow(label: 'Name', value: owner!.fullName),
        _DataRow(label: 'Email', value: owner!.email ?? 'N/A'),
        _DataRow(label: 'Phone', value: owner!.phoneNumber ?? 'N/A'),
        _DataRow(label: 'User Status', value: owner!.status ?? 'PENDING'),
        _DataRow(
          label: 'Last Login',
          value: owner!.lastLoginAt != null
              ? dateFormat.format(owner!.lastLoginAt!)
              : 'Never',
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
