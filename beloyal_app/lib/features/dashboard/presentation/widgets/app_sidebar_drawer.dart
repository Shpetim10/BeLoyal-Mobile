import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/pages/role_select_sheet.dart';
import '../../../auth/domain/models/session.dart';

/// Shared premium sidebar/drawer for Business Admin and Staff dashboards.
///
/// Opened via the hamburger icon in the top-left of the dashboard.
/// Lists all available features, with role-aware visibility.
class AppSidebarDrawer extends ConsumerWidget {
  const AppSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final isAdmin = session.activeRole == UserRole.businessAdmin;
    final isStaff = session.activeRole == UserRole.staff;
    final businessId = session.activeBusinessId ?? 0;
    final businessName = session.activeBusinessName ?? 'Your Business';
    final user = session.user;

    return Drawer(
      width: 300,
      backgroundColor: Colors.transparent,
      child: _DrawerContent(
        session: session,
        isAdmin: isAdmin,
        isStaff: isStaff,
        businessId: businessId,
        businessName: businessName,
        user: user,
      ),
    );
  }
}

// ── Drawer Content ────────────────────────────────────────────────────────────

class _DrawerContent extends ConsumerWidget {
  const _DrawerContent({
    required this.session,
    required this.isAdmin,
    required this.isStaff,
    required this.businessId,
    required this.businessName,
    required this.user,
  });

  final Session session;
  final bool isAdmin;
  final bool isStaff;
  final int businessId;
  final String businessName;
  final AuthUser user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0D1829).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(28),
            ),
            border: Border(
              right: BorderSide(
                color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Header ─────────────────────────────────────────────────
                _DrawerHeader(
                  businessName: businessName,
                  roleName: session.activeRole.displayName,
                  roleIcon: session.activeRole.icon,
                ),

                const SizedBox(height: 8),

                // ── Nav Items ──────────────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    children: [
                      // ── Main ────────────────────────────────────────────
                      _SidebarSection('Main'),
                      _SidebarItem(
                        icon: Icons.home_rounded,
                        label: 'Dashboard',
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin
                              ? '/business/dashboard'
                              : '/staff/dashboard';
                          context.go(path);
                        },
                        delay: 0,
                      ),

                      // ── Operations ──────────────────────────────────────
                      _SidebarSection('Operations'),
                      _SidebarItem(
                        icon: Icons.qr_code_scanner_rounded,
                        label: 'Earn Points (Scan QR)',
                        color: AppColors.primary,
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin
                              ? '/business/earn-points'
                              : '/staff/earn-points';
                          context.push(path);
                        },
                        delay: 1,
                      ),
                      _SidebarItem(
                        icon: Icons.category_rounded,
                        label: 'Catalog Categories',
                        color: const Color(0xFF7C3AED),
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin
                              ? '/business/$businessId/catalog-categories'
                              : '/staff/$businessId/catalog-categories';
                          context.push(path);
                        },
                        delay: 2,
                      ),
                      _SidebarItem(
                        icon: Icons.inventory_2_rounded,
                        label: 'Catalog Items',
                        color: const Color(0xFFF59E0B),
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin
                              ? '/business/$businessId/catalog-items'
                              : '/staff/$businessId/catalog-items';
                          context.push(path);
                        },
                        delay: 3,
                      ),
                      _SidebarItem(
                        icon: Icons.receipt_long_rounded,
                        label: 'Transaction Logs',
                        color: AppColors.secondary,
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin
                              ? '/business/$businessId/transactions'
                              : '/staff/$businessId/transactions';
                          context.push(path);
                        },
                        delay: 4,
                      ),

                      // ── Admin-only sections ──────────────────────────────
                      if (isAdmin) ...[
                        _SidebarSection('Business Management'),
                        _SidebarItem(
                          icon: Icons.people_rounded,
                          label: 'Staff',
                          color: AppColors.accent,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          delay: 4,
                        ),
                        _SidebarItem(
                          icon: Icons.loyalty_rounded,
                          label: 'Earning Rules',
                          color: const Color(0xFFDB2777),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(
                              '/business/$businessId/loyalty/earning-rule',
                            );
                          },
                          delay: 5,
                        ),
                        _SidebarItem(
                          icon: Icons.card_giftcard_rounded,
                          label: 'Coupons',
                          color: const Color(0xFF16A34A),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/business/$businessId/coupons');
                          },
                          delay: 6,
                        ),
                        _SidebarItem(
                          icon: Icons.tune_rounded,
                          label: 'Loyalty Settings',
                          color: const Color(0xFF0891B2),
                          onTap: () {
                            Navigator.pop(context);
                            context.push(
                              '/business/$businessId/loyalty/settings',
                            );
                          },
                          delay: 7,
                        ),
                        _SidebarItem(
                          icon: Icons.analytics_rounded,
                          label: 'Analytics',
                          color: AppColors.error,
                          onTap: () {},
                          delay: 8,
                          badge: 'Soon',
                        ),
                      ],

                      // ── Staff-only ───────────────────────────────────────
                      if (isStaff) ...[
                        _SidebarSection('Staff'),
                        _SidebarItem(
                          icon: Icons.search_rounded,
                          label: 'Customer Search',
                          color: const Color(0xFF0891B2),
                          onTap: () {},
                          delay: 4,
                          badge: 'Soon',
                        ),
                        _SidebarItem(
                          icon: Icons.redeem_rounded,
                          label: 'Redeem Rewards',
                          color: AppColors.accent,
                          onTap: () {},
                          delay: 5,
                          badge: 'Soon',
                        ),
                      ],

                      // ── Account ──────────────────────────────────────────
                      _SidebarSection('Account'),
                      _SidebarItem(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        onTap: () {
                          Navigator.pop(context);
                          final path = isAdmin ? '/profile' : '/staff/profile';
                          context.push(path);
                        },
                        delay: 8,
                      ),
                      if (user.canSwitchRoles)
                        _SidebarItem(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Switch Role',
                          onTap: () {
                            Navigator.pop(context);
                            _switchRole(context, ref, session);
                          },
                          delay: 9,
                        ),
                    ],
                  ),
                ),

                // ── Logout ──────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _LogoutButton(
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authControllerProvider).logout();
                      if (context.mounted) context.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      final bid = result['businessId'] as int?;

      if (role == UserRole.customer && !session.user.customerProfileComplete) {
        ref.read(sessionControllerProvider.notifier).switchRole(role);
        context.go('/create-profile');
        return;
      }

      ref
          .read(sessionControllerProvider.notifier)
          .switchRole(
            role,
            businessId: bid,
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

// ── Drawer Header ─────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  const _DrawerHeader({
    required this.businessName,
    required this.roleName,
    required this.roleIcon,
  });

  final String businessName;
  final String roleName;
  final String roleIcon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.08),
            AppColors.primary.withValues(alpha: 0.0),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(roleIcon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BesaHub',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleName,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SidebarSection extends StatelessWidget {
  const _SidebarSection(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.6),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.delay = 0,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final int delay;
  final String? badge;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.color ?? AppColors.textMuted;

    return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _hovered = true),
          onTapUp: (_) => setState(() => _hovered = false),
          onTapCancel: () => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _hovered
                  ? iconColor.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(widget.icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.badge!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
        .animate(delay: (widget.delay * 45).ms + 100.ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.15, end: 0, curve: Curves.easeOut);
  }
}

// ── Logout Button ─────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: AppColors.error.withValues(alpha: 0.8),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'Sign Out',
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Hamburger Icon Button ─────────────────────────────────────────────────────

/// Compact hamburger icon to open [AppSidebarDrawer].
/// Place in the top-left of any dashboard scaffold.
class HamburgerMenuButton extends StatelessWidget {
  const HamburgerMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Scaffold.of(context).openDrawer(),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.glassBorder : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          Icons.menu_rounded,
          size: 20,
          color: isDark ? AppColors.textOnDark : AppColors.textOnLight,
        ),
      ),
    );
  }
}
