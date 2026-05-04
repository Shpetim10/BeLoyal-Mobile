import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/models/session.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../auth/presentation/pages/role_select_sheet.dart';
import '../../../auth/presentation/widgets/primary_gradient_button.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';

class InvitationPendingGatePage extends ConsumerWidget {
  const InvitationPendingGatePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();

    final businessName = session.activeBusinessName ?? 'Your business';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF060B1C), Color(0xFF0D1A3A), Color(0xFF1A1035)],
          ),
        ),
        child: Stack(
          children: [
            const _AmbientGlow(top: -120, left: -80, size: 260, color: Color(0xFF34D1BF)),
            const _AmbientGlow(top: 80, right: -90, size: 240, color: Color(0xFFFFB347)),
            const _AmbientGlow(bottom: -110, left: 40, size: 220, color: Color(0xFF8DD7FF)),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: DashboardHeader(
                      canSwitchRoles: session.user.canSwitchRoles,
                      activeRoleName: session.activeRole.displayName,
                      subtitle: 'Business: $businessName',
                      onRoleSwitchTap: () => _switchRole(context, ref, session),
                      onLogoutTap: () => _logout(context, ref),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0.06),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6EE7D8), Color(0xFF3B82F6)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6EE7D8).withValues(alpha: 0.35),
                                    blurRadius: 28,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mark_email_unread_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Text(
                              'Invitation Waiting For Your Approval',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'We found an active invitation for this business, but it has not been accepted yet. Please open your invitation email and confirm it to unlock your business access.',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _PremiumInfoRow(
                              icon: Icons.email_outlined,
                              title: 'Step 1',
                              description: 'Open the invitation email sent to your account.',
                            ),
                            const SizedBox(height: 12),
                            const _PremiumInfoRow(
                              icon: Icons.how_to_reg_rounded,
                              title: 'Step 2',
                              description: 'Click the invitation acceptance link in the email.',
                            ),
                            const SizedBox(height: 12),
                            const _PremiumInfoRow(
                              icon: Icons.rocket_launch_outlined,
                              title: 'Step 3',
                              description: 'Return here and continue to your dashboard.',
                            ),
                            const SizedBox(height: 28),
                            PrimaryGradientButton(
                              label: 'I Accepted The Invitation',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () => context.go('/login'),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _logout(context, ref),
                                icon: const Icon(Icons.logout_rounded),
                                label: const Text('Log Out'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.35),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider).logout();
    if (context.mounted) context.go('/login');
  }

  Future<void> _switchRole(
    BuildContext context,
    WidgetRef ref,
    Session session,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoleSelectSheet(
        roles: session.user.roles.toList(),
        businessProfiles: session.user.businessProfiles,
      ),
    );
    if (!context.mounted || result == null) return;

    final role = result['role'] as UserRole;
    final businessId = result['businessId'] as int?;

    if (role == UserRole.customer && !session.user.customerProfileComplete) {
      ref.read(sessionControllerProvider.notifier).switchRole(role);
      context.go('/create-profile');
      return;
    }

    ref.read(sessionControllerProvider.notifier).switchRole(
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
  }
}

class _PremiumInfoRow extends StatelessWidget {
  const _PremiumInfoRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
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

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
  });

  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: math.pi / 5,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.32),
                  color.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
