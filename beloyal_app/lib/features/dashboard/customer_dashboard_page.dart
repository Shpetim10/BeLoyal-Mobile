import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/views/role_select_sheet.dart';
import 'package:besahub_app/features/auth/domain/entities/session.dart';
import 'package:besahub_app/features/auth/domain/entities/auth_user.dart';
import 'package:besahub_app/features/dashboard/widgets/dashboard_navbar.dart';
import 'package:besahub_app/features/dashboard/widgets/dashboard_header.dart';
import 'package:besahub_app/features/dashboard/widgets/stat_card.dart';

class CustomerDashboardPage extends ConsumerStatefulWidget {
  const CustomerDashboardPage({super.key});

  @override
  ConsumerState<CustomerDashboardPage> createState() =>
      _CustomerDashboardPageState();
}

class _CustomerDashboardPageState extends ConsumerState<CustomerDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgDarkGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: DashboardHeader(
                  canSwitchRoles: session?.user.canSwitchRoles ?? false,
                  activeRoleName: session?.activeRole.displayName ?? '',
                  onRoleSwitchTap: () => _switchRole(context, ref, session!),
                  onLogoutTap: () => _logout(context, ref),
                ),
              ),
              const SizedBox(height: 16),

              // ── Section title ──
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

              // ── Body ──
              Expanded(
                child: IndexedStack(
                  index: _selectedIndex,
                  children: const [
                    _CustomerHomeTab(),
                    _PlaceholderTab(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Rewards',
                    ),
                    _PlaceholderTab(
                      icon: Icons.credit_card_rounded,
                      label: 'Loyalty Card',
                    ),
                    _PlaceholderTab(
                      icon: Icons.search_rounded,
                      label: 'Search',
                    ),
                    _PlaceholderTab(
                      icon: Icons.receipt_long_rounded,
                      label: 'My Coupons',
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
        onTap: (i) => setState(() => _selectedIndex = i),
        leftItems: const [
          DashboardNavItem(icon: Icons.home_rounded, label: 'Home'),
          DashboardNavItem(icon: Icons.card_giftcard_rounded, label: 'Rewards'),
        ],
        rightItems: const [
          DashboardNavItem(icon: Icons.search_rounded, label: 'Search'),
          DashboardNavItem(icon: Icons.receipt_long_rounded, label: 'Coupons'),
        ],
        centerIcon: Icons.credit_card_rounded,
        centerLabel: 'My Card',
        // Gold accent gradient for customer (loyalty card theme)
        centerGradient: AppColors.accentGradient,
      ),
    );
  }

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Welcome Back 👋',
      1 => 'Rewards',
      2 => 'Loyalty Card',
      3 => 'Search',
      4 => 'My Coupons',
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

// ─────────────────────────── Home tab content ────────────────────────────────

class _CustomerHomeTab extends StatelessWidget {
  const _CustomerHomeTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: const [
              StatCard(
                icon: Icons.stars_rounded,
                label: 'Points Balance',
                value: '—',
                iconColor: AppColors.accent,
                subtitle: 'Earn on every visit',
              ),
              StatCard(
                icon: Icons.local_offer_rounded,
                label: 'Active Offers',
                value: '—',
                iconColor: AppColors.secondary,
                subtitle: 'Available now',
              ),
              StatCard(
                icon: Icons.card_giftcard_rounded,
                label: 'Upcoming Rewards',
                value: '—',
                iconColor: AppColors.primary,
              ),
              StatCard(
                icon: Icons.confirmation_number_rounded,
                label: 'My Coupons',
                value: '—',
                iconColor: AppColors.error,
                subtitle: 'Tap to view',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Placeholder tab ─────────────────────────────────

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
