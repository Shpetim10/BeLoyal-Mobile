import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/pages/role_select_sheet.dart';
import 'package:besahub_app/features/auth/domain/models/session.dart';
import 'package:besahub_app/features/auth/domain/models/auth_user.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_navbar.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/stat_card.dart';

class StaffDashboardPage extends ConsumerStatefulWidget {
  const StaffDashboardPage({super.key});

  @override
  ConsumerState<StaffDashboardPage> createState() => _StaffDashboardPageState();
}

class _StaffDashboardPageState extends ConsumerState<StaffDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    final businessSubtitle = session?.activeBusinessId != null
        ? 'Business: ${session!.activeBusinessName ?? session.activeBusinessId}'
        : null;

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, const Color(0xFF0F1629)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: DashboardHeader(
                  canSwitchRoles: session?.user.canSwitchRoles ?? false,
                  activeRoleName: session?.activeRole.displayName ?? '',
                  subtitle: businessSubtitle,
                  onRoleSwitchTap: () => _switchRole(context, ref, session!),
                  onLogoutTap: () => _logout(context, ref),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _pageTitle(_selectedIndex),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex >= 2 ? _selectedIndex - 1 : _selectedIndex,
                  children: const [
                    _StaffHomeTab(),
                    _PlaceholderTab(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transactions',
                    ),
                    // index 2 (Scan QR) is handled by route push, not a tab.
                    _PlaceholderTab(
                      icon: Icons.search_rounded,
                      label: 'Search',
                    ),
                    _PlaceholderTab(
                      icon: Icons.redeem_rounded,
                      label: 'Redeem Rewards',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            // Push the Earn Points flow as a full-screen route.
            context.push('/staff/earn-points');
            return;
          }
          setState(() => _selectedIndex = i);
        },
        leftItems: const [
          DashboardNavItem(icon: Icons.home_rounded, label: 'Home'),
          DashboardNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
          ),
        ],
        rightItems: const [
          DashboardNavItem(icon: Icons.search_rounded, label: 'Search'),
          DashboardNavItem(icon: Icons.redeem_rounded, label: 'Redeem'),
        ],
        centerIcon: Icons.qr_code_scanner_rounded,
        centerLabel: 'Scan QR',
        // Primary blue gradient for QR scan (matches the reference photo)
        centerGradient: AppColors.primaryGradient,
      ),
    );
  }

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Staff Portal 🛡️',
      1 => 'Transactions',
      2 => 'Scan QR Code',
      3 => 'Search',
      4 => 'Redeem Rewards',
      _ => '',
    };
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).logout();
    if (!context.mounted) return;
    context.go('/login');
  }

  void _switchRole(BuildContext context, WidgetRef ref, Session session) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSelectSheet(
        roles: session.user.roles.toList(),
        businessProfiles: session.user.businessProfiles,
      ),
    ).then((result) {
      if (result == null || !context.mounted) return;
      final role = result['role'] as UserRole;
      final businessId = result['businessId'] as int?;

      // Preserve: if switching to CUSTOMER and profile is incomplete
      if (role == UserRole.customer && !session.user.customerProfileComplete) {
        ref.read(sessionControllerProvider.notifier).switchRole(role);
        context.go('/create-profile');
        return;
      }

      ref
          .read(sessionControllerProvider.notifier)
          .switchRole(
            role,
            businessId: businessId,
            businessName: result['businessName'] as String?,
          );

      final path = switch (role) {
        UserRole.customer => '/customer/dashboard',
        UserRole.businessAdmin => '/business/dashboard',
        UserRole.staff => '/staff/dashboard',
        UserRole.superAdmin => '/admin/dashboard',
      };
      context.go(path);
    });
  }
}

class _StaffHomeTab extends StatelessWidget {
  const _StaffHomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: const [
          StatCard(
            icon: Icons.qr_code_scanner_rounded,
            label: "Today's Scans",
            value: '—',
            iconColor: AppColors.primary,
            subtitle: 'Tap to scan',
          ),
          StatCard(
            icon: Icons.pending_actions_rounded,
            label: 'Pending Redemptions',
            value: '—',
            iconColor: AppColors.accent,
            subtitle: 'Awaiting approval',
          ),
          StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Total Transactions',
            value: '—',
            iconColor: AppColors.secondary,
          ),
          StatCard(
            icon: Icons.people_rounded,
            label: 'Active Customers',
            value: '—',
            iconColor: AppColors.error,
          ),
        ],
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textMuted.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text(
            '$label\nComing Soon',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
