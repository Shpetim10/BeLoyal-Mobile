import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/pages/role_select_sheet.dart';
import 'package:besahub_app/features/auth/domain/models/session.dart';
import 'package:besahub_app/features/auth/domain/models/auth_user.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_navbar.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/dashboard_header.dart';
import 'package:besahub_app/features/dashboard/presentation/widgets/stat_card.dart';
import 'package:besahub_app/features/auth/presentation/widgets/premium_loyalty_card.dart';
import 'package:besahub_app/features/customer_loyalty/presentation/controllers/loyalty_card_provider.dart';

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
                  children: [
                    _CustomerHomeTab(),
                    _PlaceholderTab(
                      icon: Icons.card_giftcard_rounded,
                      label: 'Rewards',
                    ),
                    const SizedBox.shrink(),
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
        onTap: (i) {
          if (i == 2) {
            _showLoyaltyCardModal(context);
          } else {
            setState(() => _selectedIndex = i);
          }
        },
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
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            height: 5,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
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

                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(16),
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
                                  child: const Text(
                                    'Show your QR code at any participating location to earn points.',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
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

// Removed _CustomerLoyaltyCardTab

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
                      style: TextStyle(
                        color: AppColors.textMuted.withValues(alpha: opacity),
                        fontSize: 14,
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
              const Text(
                'Could not load your card',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your connection and try again.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
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
