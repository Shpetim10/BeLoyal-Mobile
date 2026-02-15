import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/auth/presentation/views/role_select_sheet.dart';

/// Stub customer dashboard to prove routing works.
class CustomerDashboardPage extends ConsumerWidget {
  const CustomerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bgDark, const Color(0xFF0F1A2E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top bar
                Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Customer Dashboard',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    // Role switcher chip
                    if (session != null && session.user.hasMultipleRoles)
                      ActionChip(
                        avatar: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: Text(session.activeRole.displayName),
                        onPressed: () => _switchRole(context, ref, session),
                      ),
                  ],
                ),
                const SizedBox(height: 32),
                _InfoCard(
                  icon: Icons.verified_user_rounded,
                  title: 'Welcome!',
                  subtitle:
                      'You are logged in as ${session?.activeRole.displayName ?? "Customer"}.',
                ),
                const Spacer(),
                // Logout
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider).logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _switchRole(BuildContext context, WidgetRef ref, dynamic session) {
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSelectSheet(roles: session.user.roles.toList()),
    ).then((role) {
      if (role != null) {
        ref.read(sessionControllerProvider.notifier).switchRole(role);
        final path = switch (role) {
          _ when role.toString().contains('customer') => '/customer/dashboard',
          _ when role.toString().contains('restaurantAdmin') =>
            '/business/dashboard',
          _ when role.toString().contains('staff') => '/staff/dashboard',
          _ when role.toString().contains('platformAdmin') =>
            '/admin/dashboard',
          _ => '/customer/dashboard',
        };
        context.go(path);
      }
    });
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
