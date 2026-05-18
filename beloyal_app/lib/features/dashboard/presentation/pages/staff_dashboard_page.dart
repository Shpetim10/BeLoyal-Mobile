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
import 'package:besahub_app/features/dashboard/presentation/widgets/app_sidebar_drawer.dart';
import 'package:besahub_app/features/point_transactions/presentation/pages/staff_point_transactions_page.dart';
import '../controllers/dashboard_summary_providers.dart';

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toString();
}

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
      drawer: const AppSidebarDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, Color(0xFF0F1629)],
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
                    _StaffHomeTab(
                      businessId: session?.activeBusinessId ?? 0,
                      businessName:
                          session?.activeBusinessName ?? 'Your Business',
                    ),
                    const StaffPointTransactionsPage(),
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
          final businessId =
              ref.read(sessionControllerProvider)?.activeBusinessId ?? 0;
          if (i == 2) {
            context.push('/staff/earn-points');
            return;
          }
          if (i == 3) {
            context.push('/staff/scan-coupon');
            return;
          }
          if (i == 4) {
            context.push('/staff/$businessId/catalog-items');
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
          DashboardNavItem(
            icon: Icons.document_scanner_rounded,
            label: 'Scan Coupon',
          ),
          DashboardNavItem(icon: Icons.inventory_2_rounded, label: 'Catalog'),
        ],
        centerIcon: Icons.qr_code_scanner_rounded,
        centerLabel: 'Scan QR',
        centerGradient: AppColors.primaryGradient,
      ),
    );
  }

  String _pageTitle(int index) {
    return switch (index) {
      0 => 'Staff Portal 🛡️',
      1 => 'Transactions',
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

// ── Staff Home Tab ─────────────────────────────────────────────────────────────

class _StaffHomeTab extends ConsumerWidget {
  const _StaffHomeTab({required this.businessId, required this.businessName});
  final int businessId;
  final String businessName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(staffDashboardSummaryProvider(businessId));

    return BesaRefreshIndicator(
      onRefresh: () async => ref.invalidate(staffDashboardSummaryProvider(businessId)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Business context hero ─────────────────────────────────────────
            _StaffHeroCard(businessName: businessName, businessId: businessId),
            const SizedBox(height: 20),

            // ── Primary action — Scan QR ───────────────────────────────────────
            _ScanQrBanner(businessId: businessId),
            const SizedBox(height: 20),

            // ── Today's activity ──────────────────────────────────────────────
            _SectionLabel(
              icon: Icons.today_rounded,
              label: "Today's Activity",
              iconColor: AppColors.accent,
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              data: (s) => _staffStatsGrid(s),
              loading: () => _staffStatsGrid(null),
              error: (e, _) => _StaffSummaryError(
                onRetry: () =>
                    ref.invalidate(staffDashboardSummaryProvider(businessId)),
              ),
            ),

            const SizedBox(height: 24),

            // ── Quick actions ─────────────────────────────────────────────────
            _SectionLabel(
              icon: Icons.flash_on_rounded,
              label: 'Quick Access',
              iconColor: AppColors.gold,
            ),
            const SizedBox(height: 12),
            _StaffQuickActions(businessId: businessId),

            const SizedBox(height: 24),

            // ── Staff tips ────────────────────────────────────────────────────
            _StaffTipsCard(),
          ],
        ),
      ),
    );
  }
}

Widget _staffStatsGrid(dynamic s) {
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
            icon: Icons.qr_code_scanner_rounded,
            label: "Today's Scans",
            value: v(s?.todayScansCount),
            iconColor: AppColors.primary,
            subtitle: 'Points awarded',
            accentGradient: AppColors.primaryGradient,
          ),
          StatCard(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
            value: v(s?.transactionsCount),
            iconColor: AppColors.secondary,
            subtitle: 'All time',
            accentGradient: const LinearGradient(
              colors: [AppColors.secondaryDark, AppColors.secondary],
            ),
          ),
          StatCard(
            icon: Icons.people_rounded,
            label: 'Active Customers',
            value: v(s?.activeCustomersCount),
            iconColor: AppColors.gold,
            accentGradient: AppColors.coinGradient,
          ),
        ],
      )
      .animate()
      .fadeIn(duration: 400.ms, delay: 150.ms)
      .slideY(begin: 0.08, end: 0, curve: Curves.easeOut);
}

class _StaffSummaryError extends StatelessWidget {
  const _StaffSummaryError({required this.onRetry});
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
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Could not load activity',
              style: TextStyle(color: AppColors.textOnDark, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffHeroCard extends StatelessWidget {
  const _StaffHeroCard({required this.businessName, required this.businessId});
  final String businessName;
  final int businessId;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';

    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0B1433),
                Color(0xFF1A2A6C),
                AppColors.primaryDark,
              ],
              stops: [0.0, 0.5, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.14),
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
                              Icons.shield_rounded,
                              size: 12,
                              color: AppColors.primaryLight,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'STAFF',
                              style: TextStyle(
                                color: AppColors.primaryLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
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
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    businessName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: AppColors.success),
                      const SizedBox(width: 6),
                      Text(
                        'On shift · Ready to serve customers',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

class _ScanQrBanner extends StatelessWidget {
  const _ScanQrBanner({required this.businessId});
  final int businessId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTap: () => context.push('/staff/earn-points'),
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
                        'Award loyalty points instantly',
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

class _StaffQuickActions extends StatelessWidget {
  const _StaffQuickActions({required this.businessId});
  final int businessId;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.document_scanner_rounded,
        label: 'Scan\nCoupon',
        color: const Color(0xFF10B981),
        onTap: () => context.push('/staff/scan-coupon'),
      ),
      _QuickAction(
        icon: Icons.category_rounded,
        label: 'Catalog\nCategories',
        color: const Color(0xFF7C3AED),
        onTap: () => context.push('/staff/$businessId/catalog-categories'),
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Catalog\nItems',
        color: const Color(0xFFF59E0B),
        onTap: () => context.push('/staff/$businessId/catalog-items'),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Transaction\nLogs',
        color: AppColors.secondary,
        onTap: () => context.push('/staff/$businessId/transactions'),
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
                    .animate(delay: (e.key * 60).ms + 300.ms)
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

class _StaffTipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      _TipItem(
        icon: Icons.qr_code_scanner_rounded,
        color: AppColors.primary,
        text:
            'Scan the customer\'s QR code to award points after each purchase.',
      ),
      _TipItem(
        icon: Icons.document_scanner_rounded,
        color: const Color(0xFF10B981),
        text: 'Use "Scan Coupon" to validate and redeem customer coupons.',
      ),
      _TipItem(
        icon: Icons.receipt_long_rounded,
        color: AppColors.secondary,
        text: 'View Transaction Logs to review all recent point activity.',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 15,
                    color: AppColors.gold,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Staff Tips',
                    style: TextStyle(
                      color: AppColors.textOnDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...tips.asMap().entries.map(
                (e) => e.value
                    .animate(delay: (e.key * 60).ms + 500.ms)
                    .fadeIn(duration: 300.ms)
                    .slideX(begin: 0.05, end: 0),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

class _TipItem extends StatelessWidget {
  const _TipItem({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
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
