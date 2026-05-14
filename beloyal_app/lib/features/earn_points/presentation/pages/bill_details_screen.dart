import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass.dart';
import '../controllers/earn_points_controller.dart';
import '../../data/models/resolved_guest.dart';
import '../widgets/points_calculating_indicator.dart';

/// Step 2: Bill amount entry with live points preview.
class BillDetailsScreen extends ConsumerStatefulWidget {
  const BillDetailsScreen({super.key, required this.businessId});

  final int businessId;

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  final _amountController = TextEditingController();
  final _invoiceController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Request focus on mount.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocus.requestFocus();
    });
    // Trigger preview ONCE when the user leaves the amount field.
    _amountFocus.addListener(_onAmountFocusChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _amountFocus.removeListener(_onAmountFocusChanged);
    _amountController.dispose();
    _invoiceController.dispose();
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  void _onAmountFocusChanged() {
    // Fire preview immediately if focus leaves the field.
    if (!_amountFocus.hasFocus) {
      final draft = ref.read(earnPointsControllerProvider);
      if (draft.billAmount != null && draft.billAmount! > 0) {
        _debounce?.cancel();
        ref
            .read(earnPointsControllerProvider.notifier)
            .fetchPreview(businessId: widget.businessId);
      }
    }
  }

  void _onAmountChanged(String value) {
    final amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    ref.read(earnPointsControllerProvider.notifier).updateBillAmount(amount);

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 750), () {
      if (mounted && amount != null && amount > 0) {
        ref
            .read(earnPointsControllerProvider.notifier)
            .fetchPreview(businessId: widget.businessId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(earnPointsControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            ref
                .read(earnPointsControllerProvider.notifier)
                .goToStep(WizardStep.guestIdentification);
          },
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        ),
        title: const Text(
          'Bill Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'Step 2/3',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Guest summary strip ──
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: draft.guests.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final guest = draft.guests[index];
                  return _GuestChip(guest: guest);
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Amount input ──
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bill Amount',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocus,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d+\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: _onAmountChanged,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                      suffixText: 'ALL',
                      suffixStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  if (draft.billAmount != null && draft.billAmount! > 500000)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Maximum amount is 500,000 ALL',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Points preview ──
            _PointsPreviewCard(draft: draft),
            const SizedBox(height: 16),

            // ── Optional details ──
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text(
                  'More details (optional)',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                iconColor: AppColors.textMuted,
                collapsedIconColor: AppColors.textMuted,
                children: [
                  const SizedBox(height: 4),
                  TextField(
                    controller: _invoiceController,
                    onChanged: (v) => ref
                        .read(earnPointsControllerProvider.notifier)
                        .updateInvoiceNumber(v),
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 14,
                    ),
                    maxLength: 50,
                    decoration: const InputDecoration(
                      labelText: 'Invoice Number',
                      hintText: 'INV-2026-0001',
                      counterStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    onChanged: (v) => ref
                        .read(earnPointsControllerProvider.notifier)
                        .updateNote(v),
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Note',
                      hintText: 'Table 7 split bill...',
                      counterStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _StickyCtaBar(
        isEnabled: draft.isBillValid && (draft.billAmount ?? 0) <= 500000,
        onPressed: () {
          FocusScope.of(context).unfocus();
          ref.read(earnPointsControllerProvider.notifier).goToConfirmation();
        },
        label: 'Review & Confirm',
      ),
    );
  }
}

// ── Guest chip ──────────────────────────────────────────────────────────────

class _GuestChip extends StatelessWidget {
  const _GuestChip({required this.guest});
  final ResolvedGuest guest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              guest.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            guest.firstName,
            style: const TextStyle(
              color: AppColors.textOnDark,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Points preview card ─────────────────────────────────────────────────────

class _PointsPreviewCard extends StatelessWidget {
  const _PointsPreviewCard({required this.draft});
  final EarnPointsDraftState draft;

  @override
  Widget build(BuildContext context) {
    if (draft.billAmount == null || draft.billAmount! <= 0) {
      return const SizedBox.shrink();
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(minHeight: 120),
        alignment: draft.isPreviewLoading
            ? Alignment.center
            : Alignment.centerLeft,
        child: draft.isPreviewLoading
            // ── Premium loading state ──────────────────────────────────────
            ? Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const PointsCalculatingIndicator(size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Calculating points…',
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            // ── Result / error / idle state ───────────────────────────────
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.stars_rounded,
                        color: AppColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Estimated Points',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (draft.preview != null)
                    TweenAnimationBuilder<int>(
                      tween: IntTween(
                        begin: 0,
                        end: draft.preview!.totalPoints,
                      ),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '+$value',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 6, left: 6),
                              child: Text(
                                'pts',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
                  else if (draft.previewError != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            draft.previewError!,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '—',
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: 0.4),
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                  if (draft.preview != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      draft.preview!.earningRuleSummary,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (draft.preview!.remainingPoints <
                        draft.preview!.maxPointsPerTransaction)
                      Text(
                        'Cap: ${draft.preview!.maxPointsPerTransaction} pts/txn · ${draft.preview!.remainingPoints} remaining',
                        style: TextStyle(
                          color: AppColors.warning.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ],
              ),
      ),
    );
  }
}

// ── Sticky CTA bar ──────────────────────────────────────────────────────────

class _StickyCtaBar extends StatelessWidget {
  const _StickyCtaBar({
    required this.isEnabled,
    required this.onPressed,
    required this.label,
  });

  final bool isEnabled;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomPadding),
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder.withValues(alpha: 0.15)),
        ),
      ),
      child: SizedBox(
        height: 52,
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.2),
            disabledForegroundColor: AppColors.textMuted,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
