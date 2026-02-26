import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../business_onboarding/models/business_registration_dto.dart';
import '../../business_onboarding/models/submit_application_models.dart';
import '../../profile/presentation/controllers/admin_override_controller.dart';
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
                        const SizedBox(height: 24),
                        _AdminBusinessEditPanel(app: app),
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

// ─────────────────────────── Admin Override Panel ────────────────────────────

/// Collapsible panel on ApplicationDetailsPage allowing Super Admin to edit
/// all business fields including VAT ID and status.
class _AdminBusinessEditPanel extends ConsumerStatefulWidget {
  const _AdminBusinessEditPanel({required this.app});
  final BusinessApplication app;

  @override
  ConsumerState<_AdminBusinessEditPanel> createState() =>
      _AdminBusinessEditPanelState();
}

class _AdminBusinessEditPanelState
    extends ConsumerState<_AdminBusinessEditPanel> {
  bool _expanded = false;
  bool _initialized = false;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _vatCtrl;
  BusinessType? _selectedType;
  BusinessStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.app.businessName);
    _descCtrl = TextEditingController(
      text: widget.app.businessDescription ?? '',
    );
    _addressCtrl = TextEditingController(text: widget.app.address ?? '');
    _cityCtrl = TextEditingController(text: widget.app.city);
    _countryCtrl = TextEditingController(text: widget.app.country ?? '');
    _websiteCtrl = TextEditingController(text: widget.app.websiteUrl ?? '');
    _emailCtrl = TextEditingController(text: widget.app.businessEmail);
    _phoneCtrl = TextEditingController(
      text: widget.app.businessPhoneNumber ?? '',
    );
    _vatCtrl = TextEditingController(text: widget.app.vatId);
    _selectedType = widget.app.businessType;
    _selectedStatus = widget.app.businessStatus;
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl,
      _descCtrl,
      _addressCtrl,
      _cityCtrl,
      _countryCtrl,
      _websiteCtrl,
      _emailCtrl,
      _phoneCtrl,
      _vatCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final success = await ref
        .read(adminOverrideControllerProvider.notifier)
        .updateAllFields(
          businessId: widget.app.id,
          businessName: _nameCtrl.text.trim(),
          businessType: _selectedType?.value,
          publicDescription: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
          address: _addressCtrl.text.trim().isEmpty
              ? null
              : _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
          country: _countryCtrl.text.trim().isEmpty
              ? null
              : _countryCtrl.text.trim(),
          websiteUrl: _websiteCtrl.text.trim().isEmpty
              ? null
              : _websiteCtrl.text.trim(),
          contactEmail: _emailCtrl.text.trim().isEmpty
              ? null
              : _emailCtrl.text.trim(),
          contactPhone: _phoneCtrl.text.trim().isEmpty
              ? null
              : _phoneCtrl.text.trim(),
          vatId: _vatCtrl.text.trim().isEmpty ? null : _vatCtrl.text.trim(),
          status: _selectedStatus?.value,
        );

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Business details updated'),
            ],
          ),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      setState(() => _expanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overrideState = ref.watch(adminOverrideControllerProvider);
    final isSaving = overrideState.value?.isSaving ?? false;
    final errorMessage = overrideState.value?.errorMessage;

    // Trigger load on first expand
    if (_expanded && !_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(adminOverrideControllerProvider.notifier)
            .loadBusiness(widget.app.id);
      });
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded
              ? AppColors.warning.withValues(alpha: 0.4)
              : AppColors.glassBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header / collapse toggle ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: AppColors.warning,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit Business Details',
                          style: TextStyle(
                            color: AppColors.textOnDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Super Admin override — edit all fields',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded edit form ──
          if (_expanded) ...[
            const Divider(color: AppColors.glassBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Warning banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 18,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'You are editing restricted business fields. Changes may affect compliance and visibility.',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Error banner
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          errorMessage,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                    _buildField(
                      _nameCtrl,
                      'Business name',
                      Icons.business_rounded,
                    ),
                    const SizedBox(height: 14),
                    _buildTypeDropdown(),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: _decoration(
                        'Description (optional)',
                        Icons.description_rounded,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _addressCtrl,
                      'Address (optional)',
                      Icons.place_rounded,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _cityCtrl,
                            'City',
                            Icons.location_city_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(_countryCtrl, 'Country', null),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _websiteCtrl,
                      'Website URL',
                      Icons.language_rounded,
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _emailCtrl,
                      'Contact email',
                      Icons.email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),
                    _buildField(
                      _phoneCtrl,
                      'Contact phone',
                      Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // ── Admin-restricted fields ──
                    const Divider(color: AppColors.glassBorder),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Restricted fields',
                        style: TextStyle(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    _buildField(_vatCtrl, 'VAT ID', Icons.receipt_long_rounded),
                    const SizedBox(height: 14),
                    _buildStatusDropdown(),
                    const SizedBox(height: 24),

                    // Save button
                    ElevatedButton(
                      onPressed: isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _decoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      prefixIcon: icon != null
          ? Icon(icon, size: 20, color: AppColors.textMuted)
          : null,
      filled: true,
      fillColor: AppColors.bgDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData? icon, {
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: ctrl,
      style: const TextStyle(color: AppColors.textOnDark),
      keyboardType: keyboardType,
      decoration: _decoration(label, icon),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<BusinessType>(
      value: _selectedType,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
      decoration: _decoration('Business type', Icons.category_rounded),
      items: BusinessType.values
          .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
          .toList(),
      onChanged: (val) => setState(() => _selectedType = val),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<BusinessStatus>(
      value: _selectedStatus,
      dropdownColor: AppColors.surfaceDark,
      style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
      decoration: _decoration('Business status', Icons.verified_rounded),
      items: BusinessStatus.values
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(
                s.value,
                style: const TextStyle(color: AppColors.textOnDark),
              ),
            ),
          )
          .toList(),
      onChanged: (val) => setState(() => _selectedStatus = val),
    );
  }
}
