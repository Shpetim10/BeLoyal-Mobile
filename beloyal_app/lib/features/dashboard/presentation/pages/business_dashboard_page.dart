import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../controllers/dashboard_summary_providers.dart';

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF0F1A2E)],
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
                        onRoleSwitchTap: () =>
                            _switchRole(context, ref, session!),
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
                    _BusinessHomeTab(
                      businessId: session?.activeBusinessId ?? 0,
                      businessName:
                          session?.activeBusinessName ?? 'Your Business',
                    ),
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
          DashboardNavItem(icon: Icons.card_giftcard_rounded, label: 'Coupons'),
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
      3 => 'Coupons',
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

// ── Business Home Tab ──────────────────────────────────────────────────────────

class _BusinessHomeTab extends ConsumerWidget {
  const _BusinessHomeTab({
    required this.businessId,
    required this.businessName,
  });
  final int businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(businessDashboardSummaryProvider(businessId));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Business hero card ────────────────────────────────────────────
          summaryAsync.when(
            data: (s) => _BusinessHeroCard(
              businessName: businessName,
              businessId: businessId,
              staffCount: s.staffCount,
              couponsCount: s.activeCouponsCount,
              customersCount: s.loyalCustomersCount,
            ),
            loading: () => _BusinessHeroCard(
              businessName: businessName,
              businessId: businessId,
              staffCount: null,
              couponsCount: null,
              customersCount: null,
            ),
            error: (_, __) => _BusinessHeroCard(
              businessName: businessName,
              businessId: businessId,
              staffCount: null,
              couponsCount: null,
              customersCount: null,
            ),
          ),
          const SizedBox(height: 20),

          // ── Primary action — Scan QR ──────────────────────────────────────
          _ScanQrBanner(businessId: businessId),
          const SizedBox(height: 20),

          // ── Business metrics ──────────────────────────────────────────────
          _SectionLabel(
            icon: Icons.bar_chart_rounded,
            label: 'Business Metrics',
            iconColor: AppColors.primary,
          ),
          const SizedBox(height: 12),
          summaryAsync.when(
            data: (s) => _businessStatsGrid(context, businessId, s),
            loading: () => _businessStatsGrid(context, businessId, null),
            error: (e, _) => _BusinessSummaryError(
              message: e.toString(),
              onRetry: () => ref.invalidate(
                businessDashboardSummaryProvider(businessId),
              ),
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
          _BusinessQuickActions(businessId: businessId),

          const SizedBox(height: 24),

          // ── Loyalty program snapshot ──────────────────────────────────────
          _SectionLabel(
            icon: Icons.loyalty_rounded,
            label: 'Loyalty Program',
            iconColor: const Color(0xFFDB2777),
          ),
          const SizedBox(height: 12),
          _LoyaltyProgramCard(businessId: businessId),
        ],
      ),
    );
  }
}

Widget _businessStatsGrid(BuildContext context, int businessId, dynamic s) {
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
        icon: Icons.badge_rounded,
        label: 'Staff Members',
        value: v(s?.staffCount),
        iconColor: AppColors.primary,
        subtitle: 'Active staff',
        accentGradient: AppColors.primaryGradient,
      ),
      StatCard(
        icon: Icons.card_giftcard_rounded,
        label: 'Active Coupons',
        value: v(s?.activeCouponsCount),
        iconColor: const Color(0xFF10B981),
        subtitle: 'Live campaigns',
        accentGradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF10B981)],
        ),
      ),
      StatCard(
        icon: Icons.receipt_long_rounded,
        label: 'Transactions',
        value: v(s?.transactionsTotal),
        iconColor: AppColors.secondary,
        subtitle: s != null
            ? 'Today: ${_fmt(s.todayPointsIssued)} pts'
            : 'All time',
        accentGradient: const LinearGradient(
          colors: [AppColors.secondaryDark, AppColors.secondary],
        ),
        onTap: () => context.push('/business/$businessId/transactions'),
      ),
      StatCard(
        icon: Icons.people_rounded,
        label: 'Loyal Customers',
        value: v(s?.loyalCustomersCount),
        iconColor: AppColors.gold,
        subtitle: 'With points',
        accentGradient: AppColors.coinGradient,
      ),
    ],
  )
      .animate()
      .fadeIn(duration: 400.ms, delay: 150.ms)
      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
}

class _BusinessSummaryError extends StatelessWidget {
  const _BusinessSummaryError({
    required this.message,
    required this.onRetry,
  });
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

// ── Business Hero Card ─────────────────────────────────────────────────────────

class _BusinessHeroCard extends StatelessWidget {
  const _BusinessHeroCard({
    required this.businessName,
    required this.businessId,
    required this.staffCount,
    required this.couponsCount,
    required this.customersCount,
  });
  final String businessName;
  final int businessId;
  final int? staffCount;
  final int? couponsCount;
  final int? customersCount;

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
          colors: [Color(0xFF0F1A2E), Color(0xFF1A2D4A), AppColors.primaryDark],
          stops: [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.40),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: 40,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary.withValues(alpha: 0.07),
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
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.storefront_rounded,
                          size: 12,
                          color: AppColors.accentLight,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'BUSINESS ADMIN',
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
                      Icons.store_rounded,
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
                  color: Colors.white60,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                businessName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _HeroStat(label: 'Staff', value: v(staffCount)),
                  const SizedBox(width: 20),
                  _HeroStat(label: 'Coupons', value: v(couponsCount)),
                  const SizedBox(width: 20),
                  _HeroStat(label: 'Customers', value: v(customersCount)),
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
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ── Scan QR Banner ─────────────────────────────────────────────────────────────

class _ScanQrBanner extends StatelessWidget {
  const _ScanQrBanner({required this.businessId});
  final int businessId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/business/earn-points'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan Customer QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Award loyalty points to customers',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 100.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

// ── Business Quick Actions ─────────────────────────────────────────────────────

class _BusinessQuickActions extends StatelessWidget {
  const _BusinessQuickActions({required this.businessId});
  final int businessId;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.loyalty_rounded,
        label: 'Earning\nRules',
        color: const Color(0xFFDB2777),
        onTap: () =>
            context.push('/business/$businessId/loyalty/earning-rule'),
      ),
      _QuickAction(
        icon: Icons.tune_rounded,
        label: 'Loyalty\nSettings',
        color: const Color(0xFF0891B2),
        onTap: () =>
            context.push('/business/$businessId/loyalty/settings'),
      ),
      _QuickAction(
        icon: Icons.category_rounded,
        label: 'Catalog\nCategories',
        color: const Color(0xFF7C3AED),
        onTap: () =>
            context.push('/business/$businessId/catalog-categories'),
      ),
      _QuickAction(
        icon: Icons.document_scanner_rounded,
        label: 'Scan\nCoupon',
        color: const Color(0xFF10B981),
        onTap: () => context.push('/business/scan-coupon'),
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
                    .animate(delay: (e.key * 60).ms + 250.ms)
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

// ── Loyalty Program Card ───────────────────────────────────────────────────────

class _LoyaltyProgramCard extends StatelessWidget {
  const _LoyaltyProgramCard({required this.businessId});
  final int businessId;

  @override
  Widget build(BuildContext context) {
    final features = [
      _LoyaltyFeature(
        icon: Icons.loyalty_rounded,
        color: const Color(0xFFDB2777),
        title: 'Earning Rules',
        subtitle: 'Define how customers earn points',
        onTap: () =>
            context.push('/business/$businessId/loyalty/earning-rule'),
      ),
      _LoyaltyFeature(
        icon: Icons.tune_rounded,
        color: const Color(0xFF0891B2),
        title: 'Loyalty Settings',
        subtitle: 'Tiers, expiry, and redemption config',
        onTap: () =>
            context.push('/business/$businessId/loyalty/settings'),
      ),
      _LoyaltyFeature(
        icon: Icons.card_giftcard_rounded,
        color: AppColors.primary,
        title: 'Coupons',
        subtitle: 'Manage discount campaigns',
        onTap: () => context.push('/business/$businessId/coupons'),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: features
            .asMap()
            .entries
            .map(
              (e) => Column(
                children: [
                  e.value
                      .animate(delay: (e.key * 60).ms + 450.ms)
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: 0.05, end: 0),
                  if (e.key < features.length - 1)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color: AppColors.glassBorder.withValues(alpha: 0.6),
                    ),
                ],
              ),
            )
            .toList(),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _LoyaltyFeature extends StatefulWidget {
  const _LoyaltyFeature({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_LoyaltyFeature> createState() => _LoyaltyFeatureState();
}

class _LoyaltyFeatureState extends State<_LoyaltyFeature> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _pressed
              ? widget.color.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

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

// ── Placeholder Tab ────────────────────────────────────────────────────────────

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
