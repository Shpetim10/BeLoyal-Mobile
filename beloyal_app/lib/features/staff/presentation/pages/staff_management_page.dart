import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../domain/models/staff_member.dart';
import '../controllers/staff_controller.dart';
import '../widgets/staff_summary_row.dart';
import '../widgets/staff_search_bar.dart';
import '../widgets/staff_card.dart';
import '../widgets/staff_empty_state.dart';
import '../widgets/invite_staff_sheet.dart';
import '../widgets/staff_detail_sheet.dart';

/// The main Staff Management super-page for Business and Super Admins.
class StaffManagementPage extends ConsumerStatefulWidget {
  const StaffManagementPage({super.key});

  @override
  ConsumerState<StaffManagementPage> createState() =>
      _StaffManagementPageState();
}

class _StaffManagementPageState extends ConsumerState<StaffManagementPage> {
  @override
  void initState() {
    super.initState();
    // Fetch data when page initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffControllerProvider.notifier).refresh();
    });
  }

  void _showInviteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InviteStaffSheet(),
    );
  }

  void _showDetailSheet(StaffMember member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StaffDetailSheet(member: member),
    );
  }

  Future<void> _handleDeactivate(StaffMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Deactivate staff member?',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: const Text(
          'They will lose access to staff features for this business, but historical records remain.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref
        .read(staffControllerProvider.notifier)
        .updateStatus(member.id, MemberStatus.inactive);

    if (error == null && mounted) {
      _showToast('Member deactivated');
    } else if (error != null && mounted) {
      _showToast(error, isError: true);
    }
  }

  Future<void> _handleReactivate(StaffMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reactivate staff member?',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: const Text(
          'They will regain access to staff features for this business immediately.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref
        .read(staffControllerProvider.notifier)
        .updateStatus(member.id, MemberStatus.active);

    if (error == null && mounted) {
      _showToast('Member reactivated');
    } else if (error != null && mounted) {
      _showToast(error, isError: true);
    }
  }

  Future<void> _handleResendInvite(StaffMember member) async {
    final error = await ref
        .read(staffControllerProvider.notifier)
        .resendInvite(member.id);

    if (mounted) {
      if (error == null) {
        _showToast('Invite resent completely');
      } else {
        _showToast(error, isError: true);
      }
    }
  }

  Future<void> _handleCancelInvite(StaffMember member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Cancel Invite?',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        content: const Text(
          'This will revoke the pending invite link sent to this email.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Back',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Invite'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await ref
        .read(staffControllerProvider.notifier)
        .updateStatus(member.id, MemberStatus.inactive);

    if (error == null && mounted) {
      _showToast('Invite cancelled');
    } else if (error != null && mounted) {
      _showToast(error, isError: true);
    }
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(
          bottom: 90,
          left: 20,
          right: 20,
        ), // Above bottom nav
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAsync = ref.watch(filteredStaffProvider);
    final rawAsync = ref.watch(staffControllerProvider);
    final hasNoStaffEver =
        rawAsync.hasValue &&
        (rawAsync.value?.isEmpty ?? true) &&
        !rawAsync.isLoading;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => ref.read(staffControllerProvider.notifier).refresh(),
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceDark,
          child: CustomScrollView(
            slivers: [
              // 1. Summary Cards
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: StaffSummaryRow(),
                ),
              ),

              // 2. Sticky Search Bar (Only if they have staff)
              if (!hasNoStaffEver)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: StickySearchBarDelegate(),
                ),

              // 3. Staff List or States
              filteredAsync.when(
                loading: () => const SliverPadding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 180),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: const BesaLoader(),
                      ),
                    ),
                  ),
                ),
                error: (err, stack) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                  sliver: SliverToBoxAdapter(
                    child: StaffEmptyState.error(
                      onInvite: () =>
                          ref.read(staffControllerProvider.notifier).refresh(),
                    ),
                  ),
                ),
                data: (staffList) {
                  if (hasNoStaffEver) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                      sliver: SliverToBoxAdapter(
                        child: StaffEmptyState.empty(
                          onInvite: _showInviteSheet,
                        ),
                      ),
                    );
                  }
                  if (staffList.isEmpty) {
                    final query = ref.watch(staffSearchQueryProvider);
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                      sliver: SliverToBoxAdapter(
                        child: StaffEmptyState.noResults(
                          query: query,
                          onInvite: () {
                            ref
                                .read(staffSearchQueryProvider.notifier)
                                .updateQuery('');
                            ref
                                .read(staffFilterProvider.notifier)
                                .updateFilter(StaffFilter.all);
                          },
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 180),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final member = staffList[index];
                        return StaffCard(
                              member: member,
                              onTap: () => _showDetailSheet(member),
                              onDeactivate: () => _handleDeactivate(member),
                              onReactivate: () => _handleReactivate(member),
                              onResendInvite: () => _handleResendInvite(member),
                              onCancelInvite: () => _handleCancelInvite(member),
                            )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(
                              begin: 0.1,
                              duration: 400.ms,
                              curve: Curves.easeOut,
                            );
                      }, childCount: staffList.length),
                    ),
                  );
                },
              ),
            ],
          ),
        ),

        // Floating 'Invite Staff' button at bottom right (matches premium layout)
        Positioned(
          bottom: 140, // Shifted up to firmly clear the Dashboard NavBar
          right: 20,
          child:
              FloatingActionButton.extended(
                heroTag: 'besa-fab-staff-invite',
                onPressed: _showInviteSheet,
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                icon: const Icon(Icons.person_add_rounded),
                label: const Text(
                  'Invite',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                elevation: 8,
              ).animate().scale(
                delay: 200.ms,
                duration: 400.ms,
                curve: Curves.elasticOut,
              ),
        ),
      ],
    );
  }
}
