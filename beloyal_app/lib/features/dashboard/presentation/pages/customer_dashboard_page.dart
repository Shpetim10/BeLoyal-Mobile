import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/pages/role_select_sheet.dart';
import 'package:besahub_app/features/auth/domain/models/session.dart';
import 'package:besahub_app/features/auth/domain/models/auth_user.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_navbar.dart';
import 'package:besahub_app/features/auth/presentation/widgets/premium_loyalty_card.dart';
import 'package:besahub_app/features/customer_loyalty/presentation/controllers/loyalty_card_provider.dart';
import 'package:besahub_app/features/customer_ui/presentation/tabs/customer_home_tab.dart';
import 'package:besahub_app/features/customer_ui/presentation/tabs/customer_rewards_tab.dart';
import 'package:besahub_app/features/customer_ui/presentation/tabs/customer_orders_tab.dart';
import 'package:besahub_app/features/customer_ui/presentation/tabs/customer_profile_tab.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';

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
    final customerData = ref.watch(customerDataProvider);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgDarkGradient),
        child: SafeArea(
          bottom: false,
          child: customerData.when(
            loading: () => const CustomerLoadingState(),
            error: (_, __) => CustomerErrorState(
              onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
            ),
            data: (data) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CustomerTopBar(
                  customer: data.summary,
                  session: session,
                  selectedIndex: _selectedIndex,
                  onRoleSwitchTap: () => _switchRole(context, ref, session!),
                  onLogoutTap: () => _logout(context, ref),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      CustomerHomeTab(),
                      CustomerRewardsTab(),
                      SizedBox.shrink(),
                      CustomerOrdersTab(),
                      CustomerProfileTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: DashboardNavBar(
        selectedIndex: _selectedIndex,
        onTap: (i) {
          if (i == 2) {
            _showLoyaltyCardModal(context);
          } else {
            setState(() => _selectedIndex = i);
          }
        },
        leftItems: const [
          DashboardNavItem(icon: Icons.home_rounded, label: 'Home'),
          DashboardNavItem(icon: Icons.card_giftcard_rounded, label: 'Coupons'),
        ],
        rightItems: const [
          DashboardNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Transactions',
          ),
          DashboardNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ],
        centerIcon: Icons.credit_card_rounded,
        centerLabel: 'My Card',
        centerGradient: AppColors.coinGradient,
      ),
    );
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

  Future<void> _showLoyaltyCardModal(BuildContext context) async {
    double? originalBrightness;
    try {
      originalBrightness = await ScreenBrightness().application;
      await ScreenBrightness().setApplicationScreenBrightness(1.0);
    } catch (e) {
      debugPrint('Could not set screen brightness: $e');
    }

    if (!context.mounted) return;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.85),
        builder: (modalContext) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * 150),
                child: child,
              );
            },
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Consumer(
                  builder: (context, ref, child) {
                    final cardAsync = ref.watch(loyaltyCardProvider);
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Handle
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          // Title
                          Text(
                            'Your Loyalty Card',
                            style: AppTypography.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Show this QR code at any participating business',
                            style: AppTypography.dmSans(
                              fontSize: 12,
                              color: AppColors.textMutedDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          cardAsync.when(
                            loading: () => const _CardLoadingSkeleton(),
                            error: (err, _) => _CardErrorView(
                              onRetry: () =>
                                  ref.invalidate(loyaltyCardProvider),
                            ),
                            data: (card) => PremiumLoyaltyCard(
                              firstName: card.firstName,
                              lastName: card.lastName,
                              qrToken: card.qrToken,
                              manualCode: card.manualCode,
                              shimmer: true,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Info banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: AppColors.primary.withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Show your QR code at any participating location to earn points.',
                                    style: AppTypography.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMutedDark,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    } finally {
      if (originalBrightness != null) {
        try {
          await ScreenBrightness().setApplicationScreenBrightness(
            originalBrightness,
          );
        } catch (e) {
          debugPrint('Could not restore screen brightness: $e');
        }
      }
    }
  }
}

// ─── Customer Top Bar ─────────────────────────────────────────────────────────

class _CustomerTopBar extends ConsumerWidget {
  const _CustomerTopBar({
    required this.customer,
    required this.session,
    required this.selectedIndex,
    required this.onRoleSwitchTap,
    required this.onLogoutTap,
  });

  final dynamic customer;
  final Session? session;
  final int selectedIndex;
  final VoidCallback onRoleSwitchTap;
  final VoidCallback onLogoutTap;

  String _pageTitle(int index, String firstName) => switch (index) {
    0 => 'Good ${_greeting()}, $firstName 👋',
    1 => 'Coupons',
    2 => 'Loyalty Card',
    3 => 'Transactions',
    4 => 'Profile',
    _ => '',
  };

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canSwitch = session?.user.canSwitchRoles ?? false;
    final loyaltyCard = ref.watch(loyaltyCardProvider).asData?.value;
    final displayFirstName = loyaltyCard?.firstName.isNotEmpty == true
        ? loyaltyCard!.firstName
        : customer.firstNameOrFallback;
    final displayInitials =
        '${(loyaltyCard?.firstName.isNotEmpty == true ? loyaltyCard!.firstName[0] : customer.initials)}'
        '${(loyaltyCard?.lastName.isNotEmpty == true ? loyaltyCard!.lastName[0] : '').toUpperCase()}';
    final avatarInitials = displayInitials.trim().isEmpty
        ? customer.initials
        : displayInitials.trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // BesaHub logo
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppColors.primaryGradient.createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'BesaHub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const Spacer(),
              // Role toggle
              if (canSwitch) ...[
                GestureDetector(
                  onTap: onRoleSwitchTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.swap_horiz_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          session?.activeRole.displayName ?? '',
                          style: AppTypography.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Avatar menu
              _AvatarMenu(initials: avatarInitials, onLogoutTap: onLogoutTap),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _pageTitle(selectedIndex, displayFirstName),
                key: ValueKey(selectedIndex),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarMenu extends ConsumerWidget {
  const _AvatarMenu({required this.initials, required this.onLogoutTap});
  final String initials;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'Profile Options',
      onSelected: (value) {
        if (value == 'logout') {
          onLogoutTap();
        }
      },
      offset: const Offset(0, 50),
      color: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          border: Border.all(color: AppColors.glassBorder, width: 2),
        ),
        child: Center(
          child: Text(
            initials,
            style: AppTypography.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      itemBuilder: (_) => [
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 20,
                color: AppColors.error,
              ),
              const SizedBox(width: 12),
              Text(
                'Log Out',
                style: AppTypography.dmSans(
                  fontSize: 14,
                  color: AppColors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Card Loading / Error States ─────────────────────────────────────────────

class _CardLoadingSkeleton extends StatefulWidget {
  const _CardLoadingSkeleton();

  @override
  State<_CardLoadingSkeleton> createState() => _CardLoadingSkeletonState();
}

class _CardLoadingSkeletonState extends State<_CardLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.586;
        return AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) {
            final opacity = 0.3 + 0.25 * _pulse.value;
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: opacity * 0.15),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: opacity * 0.4),
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.credit_card_rounded,
                      size: 48,
                      color: AppColors.accent.withValues(alpha: opacity),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your card…',
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        color: AppColors.textMutedDark.withValues(
                          alpha: opacity,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CardErrorView extends StatelessWidget {
  const _CardErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width * 1.586;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: AppColors.error.withValues(alpha: 0.05),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: AppColors.error.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load your card',
                style: AppTypography.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMutedDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Check your connection and try again.',
                style: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.textMutedDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ),
        );
      },
    );
  }
}
