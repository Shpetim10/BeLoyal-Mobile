import 'package:besahub_app/features/admin/presentation/pages/admin_all_businesses_page.dart';
import 'package:besahub_app/features/admin/presentation/pages/admin_monitoring_page.dart';
import 'package:besahub_app/features/admin/presentation/pages/admin_platform_users_page.dart';
import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/widgets/besa_loader.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/pages/role_select_sheet.dart';
import 'package:besahub_app/features/auth/domain/models/session.dart';
import 'package:besahub_app/features/auth/domain/models/auth_user.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_navbar.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/stat_card.dart';
import '../../../admin/presentation/pages/business_applications_page.dart';
import '../controllers/dashboard_summary_providers.dart';

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF0B1A12)],
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
                  index: _selectedIndex,
                  children: const [
                    _AdminHomeTab(),
                    BusinessApplicationsPage(),
                    AdminAllBusinessesPage(),
                    AdminPlatformUsersPage(),
                    AdminMonitoringPage(),
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
          DashboardNavItem(
            icon: Icons.assignment_turned_in_rounded,
            label: 'Pending',
          ),
        ],
        rightItems: const [
          DashboardNavItem(icon: Icons.people_rounded, label: 'Users'),
          DashboardNavItem(icon: Icons.monitor_heart_rounded, label: 'Monitor'),
        ],
        centerIcon: Icons.business_rounded,
        centerLabel: 'Businesses',
        centerGradient: const LinearGradient(
          colors: [AppColors.secondary, AppColors.secondaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Platform Overview 🌐',
      1 => 'Pending Approvals',
      2 => 'All Businesses',
      3 => 'Platform Users',
      4 => 'Monitoring',
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

// ── Admin Home Tab ─────────────────────────────────────────────────────────────

class _AdminHomeTab extends ConsumerWidget {
  const _AdminHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(adminPlatformSummaryProvider);

    return BesaRefreshIndicator(
      onRefresh: () async => ref.invalidate(adminPlatformSummaryProvider),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Platform hero card ────────────────────────────────────────────
            summaryAsync.when(
              data: (s) => _PlatformHeroCard(
                totalBusinesses: s.totalBusinesses,
                pendingCount: s.pendingApplicationsCount,
                usersCount: s.registeredUsersCount,
              ),
              loading: () => _PlatformHeroCard(
                totalBusinesses: null,
                pendingCount: null,
                usersCount: null,
              ),
              error: (_, __) => _PlatformHeroCard(
                totalBusinesses: null,
                pendingCount: null,
                usersCount: null,
              ),
            ),
            const SizedBox(height: 20),

            // ── Stats label ───────────────────────────────────────────────────
            _SectionLabel(
              icon: Icons.bar_chart_rounded,
              label: 'Platform Metrics',
              iconColor: AppColors.primary,
            ),
            const SizedBox(height: 12),

            // ── Stats grid ────────────────────────────────────────────────────
            summaryAsync.when(
              data: (s) => _adminStatsGrid(context, s),
              loading: () => _adminStatsGrid(context, null),
              error: (e, _) => _AdminSummaryError(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminPlatformSummaryProvider),
              ),
            ),

            const SizedBox(height: 24),

            // ── Quick actions ─────────────────────────────────────────────────
            _SectionLabel(
              icon: Icons.flash_on_rounded,
              label: 'Quick Actions',
              iconColor: AppColors.gold,
            ),
            const SizedBox(height: 12),
            _AdminQuickActions(),

            const SizedBox(height: 24),

            // ── Platform status strip ─────────────────────────────────────────
            _SectionLabel(
              icon: Icons.shield_rounded,
              label: 'Platform Status',
              iconColor: AppColors.success,
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (s) => _PlatformStatusStrip(health: s.health),
              loading: () => _PlatformStatusStrip(health: null),
              error: (_, __) => _PlatformStatusStrip(health: null),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _adminStatsGrid(BuildContext context, dynamic s) {
  String v(int? n) => n != null ? _fmt(n) : '—';

  return GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
    childAspectRatio: 1.05,
    children: [
      StatCard(
        icon: Icons.business_rounded,
        label: 'Total Businesses',
        value: v(s?.totalBusinesses),
        iconColor: AppColors.primary,
        subtitle: s != null ? '${_fmt(s.activeBusinesses)} active' : null,
        accentGradient: AppColors.primaryGradient,
      ),
      StatCard(
        icon: Icons.pending_rounded,
        label: 'Pending Approvals',
        value: v(s?.pendingApplicationsCount),
        iconColor: AppColors.accent,
        subtitle: 'Awaiting review',
        accentGradient: const LinearGradient(
          colors: [AppColors.accentDark, AppColors.accent],
        ),
      ),
      StatCard(
        icon: Icons.people_rounded,
        label: 'Registered Users',
        value: v(s?.registeredUsersCount),
        iconColor: AppColors.secondary,
        accentGradient: const LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondary],
        ),
      ),
      StatCard(
        icon: Icons.monitor_heart_rounded,
        label: 'System Health',
        value: s != null ? (s.health.isUp ? 'UP' : 'DEGRADED') : '—',
        iconColor: s != null
            ? (s.health.isUp ? AppColors.success : AppColors.error)
            : AppColors.success,
        subtitle: 'All services',
        accentGradient: LinearGradient(
          colors: s != null && !s.health.isUp
              ? [const Color(0xFF991B1B), AppColors.error]
              : [const Color(0xFF16A34A), AppColors.success],
        ),
      ),
    ],
  )
      .animate()
      .fadeIn(duration: 400.ms, delay: 100.ms)
      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
}

class _AdminSummaryError extends StatelessWidget {
  const _AdminSummaryError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load metrics',
              style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.75),
                  fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _PlatformHeroCard extends StatelessWidget {
  const _PlatformHeroCard({
    required this.totalBusinesses,
    required this.pendingCount,
    required this.usersCount,
  });

  final int? totalBusinesses;
  final int? pendingCount;
  final int? usersCount;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    String v(int? n) => n != null ? _fmt(n) : '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A0935), Color(0xFF2D1060), AppColors.primary],
          stops: [0.0, 0.45, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 12,
                          color: AppColors.accentLight,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'SUPER ADMIN',
                          style: TextStyle(
                            color: AppColors.accentLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.public_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$greeting,',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'BesaHub Platform',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroStat(label: 'Businesses', value: v(totalBusinesses)),
                  const SizedBox(width: 20),
                  _HeroStat(label: 'Pending', value: v(pendingCount)),
                  const SizedBox(width: 20),
                  _HeroStat(label: 'Users', value: v(usersCount)),
                ],
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AdminQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.assignment_turned_in_rounded,
        label: 'Review\nApplications',
        color: AppColors.accent,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.business_center_rounded,
        label: 'All\nBusinesses',
        color: AppColors.secondary,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.person_search_rounded,
        label: 'Find\nUser',
        color: AppColors.primary,
        onTap: () {},
      ),
      _QuickAction(
        icon: Icons.analytics_rounded,
        label: 'Analytics',
        color: AppColors.gold,
        onTap: () {},
      ),
    ];

    return Row(
      children: actions
          .asMap()
          .entries
          .map(
            (e) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: e.key == 0 ? 0 : 6,
                  right: e.key == actions.length - 1 ? 0 : 6,
                ),
                child: e.value
                    .animate(delay: (e.key * 60).ms + 200.ms)
                    .fadeIn(duration: 300.ms)
                    .scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
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
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withValues(alpha: 0.22)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textOnDark.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlatformStatusStrip extends StatelessWidget {
  const _PlatformStatusStrip({required this.health});
  final dynamic health; // PlatformHealthDto or null while loading

  @override
  Widget build(BuildContext context) {
    bool ok(bool Function() check) {
      if (health == null) return true;
      return check();
    }

    String label(bool Function() check) {
      if (health == null) return '—';
      return check() ? 'Operational' : 'Down';
    }

    final items = [
      _StatusItem(
        label: 'Database',
        status: label(() => health.databaseUp as bool),
        ok: ok(() => health.databaseUp as bool),
      ),
      _StatusItem(
        label: 'Redis',
        status: label(() => health.redisUp as bool),
        ok: ok(() => health.redisUp as bool),
      ),
      _StatusItem(
        label: 'Disk Space',
        status: label(() => health.diskSpaceUp as bool),
        ok: ok(() => health.diskSpaceUp as bool),
      ),
      _StatusItem(
        label: 'Overall',
        status: label(() => health.isUp as bool),
        ok: ok(() => health.isUp as bool),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: items
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value
                      .animate(delay: (e.key * 50).ms + 400.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                  if (e.key < items.length - 1)
                    Divider(
                      height: 16,
                      color: AppColors.glassBorder.withValues(alpha: 0.5),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  const _StatusItem({
    required this.label,
    required this.status,
    required this.ok,
  });
  final String label;
  final String status;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? AppColors.success : AppColors.error;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.icon,
    required this.label,
    required this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textOnDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

