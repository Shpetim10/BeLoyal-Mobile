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
import 'package:besahub_app/features/dashboard/presentation/widgets/app_sidebar_drawer.dart';
import 'package:besahub_app/features/coupons/presentation/pages/coupon_list_page.dart';
import 'package:besahub_app/features/staff/presentation/pages/staff_management_page.dart';
import 'package:besahub_app/features/point_transactions/presentation/pages/point_transactions_page.dart';

class BusinessDashboardPage extends ConsumerStatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  ConsumerState<BusinessDashboardPage> createState() =>
      _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends ConsumerState<BusinessDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    final businessSubtitle = session?.activeBusinessId != null
        ? 'Business: ${session!.activeBusinessName ?? session.activeBusinessId}'
        : null;

    return Scaffold(
      extendBody: true,
      drawer: const AppSidebarDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, const Color(0xFF0F1A2E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    const HamburgerMenuButton(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DashboardHeader(
                        canSwitchRoles: session?.user.canSwitchRoles ?? false,
                        activeRoleName: session?.activeRole.displayName ?? '',
                        subtitle: businessSubtitle,
                        onRoleSwitchTap: () => _switchRole(context, ref, session!),
                        onLogoutTap: () => _logout(context, ref),
                      ),
                    ),
                  ],
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
                  index: _selectedIndex,
                  children: [
                    _BusinessHomeTab(businessId: session?.activeBusinessId ?? 0),
                    const StaffManagementPage(),
                    const _PlaceholderTab(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Scan QR',
                    ),
                    CouponListPage(
                      businessId: session?.activeBusinessId ?? 0,
                      embedded: true,
                    ),
                    const PointTransactionsPage(),
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
            context.push('/business/earn-points');
            return;
          }
          setState(() => _selectedIndex = i);
        },
        leftItems: const [
          DashboardNavItem(icon: Icons.home_rounded, label: 'Home'),
          DashboardNavItem(icon: Icons.people_rounded, label: 'Staff'),
        ],
        rightItems: const [
          DashboardNavItem(icon: Icons.card_giftcard_rounded, label: 'Rewards'),
          DashboardNavItem(icon: Icons.list_alt_rounded, label: 'Logs'),
        ],
        centerIcon: Icons.qr_code_scanner_rounded,
        centerLabel: 'Scan QR',
        centerGradient: AppColors.primaryGradient,
      ),
    );
  }

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Management Hub 🏪',
      1 => 'Staff',
      2 => 'Scan QR Code',
      3 => 'Rewards',
      4 => 'Transaction Logs',
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

class _BusinessHomeTab extends StatelessWidget {
  const _BusinessHomeTab({required this.businessId});
  final int businessId;

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
        children: [
          const StatCard(
            icon: Icons.badge_rounded,
            label: 'Staff Members',
            value: '—',
            iconColor: AppColors.primary,
            subtitle: 'View all staff',
          ),
          const StatCard(
            icon: Icons.card_giftcard_rounded,
            label: 'Active Rewards',
            value: '—',
            iconColor: AppColors.accent,
            subtitle: 'Live campaigns',
          ),
          GestureDetector(
            onTap: () => context.push('/business/$businessId/catalog-categories'),
            child: const StatCard(
              icon: Icons.category_rounded,
              label: 'Catalog Categories',
              value: '—',
              iconColor: Color(0xFF7C3AED),
              subtitle: 'Manage catalog',
            ),
          ),
          const StatCard(
            icon: Icons.analytics_rounded,
            label: 'Revenue Overview',
            value: '—',
            iconColor: AppColors.error,
            subtitle: 'Analytics',
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
