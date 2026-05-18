import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../data/models/admin_business_dtos.dart';
import '../controllers/admin_business_controller.dart';

class AdminPlatformUsersPage extends ConsumerStatefulWidget {
  const AdminPlatformUsersPage({super.key});

  @override
  ConsumerState<AdminPlatformUsersPage> createState() =>
      _AdminPlatformUsersPageState();
}

class _AdminPlatformUsersPageState
    extends ConsumerState<AdminPlatformUsersPage> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminPlatformUsersProvider);
    final query = ref.watch(adminUserSearchQueryProvider);

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: _SearchField(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(adminUserSearchQueryProvider.notifier).update(v),
          ),
        ),

        // ── List ───────────────────────────────────────────────────────────
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: BesaLoader()),
            error: (err, _) => _ErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(adminPlatformUsersProvider),
            ),
            data: (users) {
              final filtered = _filter(users, query);
              if (filtered.isEmpty) {
                return _EmptyState(query: query);
              }
              return RefreshIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.surfaceDark,
                onRefresh: () async =>
                    ref.invalidate(adminPlatformUsersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _UserCard(
                    user: filtered[i],
                    index: i,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<PlatformUserSummaryDto> _filter(
    List<PlatformUserSummaryDto> users,
    String query,
  ) {
    if (query.isEmpty) return users;
    final q = query.toLowerCase();
    return users.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          (u.phoneNumber?.toLowerCase().contains(q) ?? false);
    }).toList();
  }
}

// ── Search Field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
  });
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textOnDark, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search by name, email or username…',
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                  onPressed: () {
                    controller.clear();
                    onChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

// ── User Card ─────────────────────────────────────────────────────────────────

class _UserCard extends StatefulWidget {
  const _UserCard({required this.user, required this.index});
  final PlatformUserSummaryDto user;
  final int index;

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final initial =
        u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ─────────────────────────────────────────────
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _avatarGradient(u),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _avatarGradient(u)
                                .last
                                .withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            u.fullName.isNotEmpty ? u.fullName : u.username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            u.email,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Expand/collapse icon
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Role chips ─────────────────────────────────────────────
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: u.roles.map((r) => _RoleChip(role: r)).toList(),
                ),

                // ── Expanded details ───────────────────────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _expanded
                      ? _UserExpandedSection(user: u)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(delay: (widget.index * 40).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }

  List<Color> _avatarGradient(PlatformUserSummaryDto u) {
    if (u.isSuperAdmin) {
      return [AppColors.primaryDark, AppColors.primary];
    }
    if (u.isCustomer) {
      return [AppColors.secondaryDark, AppColors.secondary];
    }
    return [AppColors.accentDark, AppColors.accent];
  }
}

// ── Role Chip ─────────────────────────────────────────────────────────────────

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final (color, label) = _roleStyle(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  (Color, String) _roleStyle(String role) {
    final r = role.toUpperCase();
    if (r.contains('SUPER_ADMIN')) return (AppColors.primary, 'SUPER ADMIN');
    if (r.contains('BUSINESS_ADMIN')) return (AppColors.accent, 'BIZ ADMIN');
    if (r.contains('STAFF')) return (AppColors.gold, 'STAFF');
    if (r.contains('CUSTOMER')) return (AppColors.secondary, 'CUSTOMER');
    return (AppColors.textMuted, role.replaceAll('ROLE_', ''));
  }
}

// ── Expanded section ──────────────────────────────────────────────────────────

class _UserExpandedSection extends StatelessWidget {
  const _UserExpandedSection({required this.user});
  final PlatformUserSummaryDto user;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, yyyy');

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: AppColors.glassBorder, height: 1),
          const SizedBox(height: 14),

          // ── Meta info ────────────────────────────────────────────────────
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _MetaItem(
                icon: Icons.verified_rounded,
                label: 'Email',
                value: user.emailVerified ? 'Verified' : 'Not verified',
                valueColor: user.emailVerified
                    ? AppColors.success
                    : AppColors.warning,
              ),
              _MetaItem(
                icon: Icons.circle,
                label: 'Status',
                value: user.status,
                valueColor: user.status == 'ACTIVE'
                    ? AppColors.success
                    : AppColors.error,
              ),
              if (user.lastLoginAt != null)
                _MetaItem(
                  icon: Icons.login_rounded,
                  label: 'Last login',
                  value: fmt.format(user.lastLoginAt!),
                  valueColor: AppColors.textMuted,
                ),
              if (user.createdAt != null)
                _MetaItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'Joined',
                  value: fmt.format(user.createdAt!),
                  valueColor: AppColors.textMuted,
                ),
              if (user.phoneNumber != null)
                _MetaItem(
                  icon: Icons.phone_rounded,
                  label: 'Phone',
                  value: user.phoneNumber!,
                  valueColor: AppColors.textMuted,
                ),
            ],
          ),

          // ── Loyalty summary ───────────────────────────────────────────────
          if (user.loyaltySummary != null) ...[
            const SizedBox(height: 14),
            _LoyaltySummaryBlock(summary: user.loyaltySummary!),
          ],

          // ── Business memberships ──────────────────────────────────────────
          if (user.businessMemberships.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Business Memberships',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...user.businessMemberships.map(
              (m) => _MembershipTile(membership: m),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: valueColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LoyaltySummaryBlock extends StatelessWidget {
  const _LoyaltySummaryBlock({required this.summary});
  final LoyaltySummaryDto summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.secondary.withValues(alpha: 0.08),
            AppColors.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: AppColors.gold,
                size: 14,
              ),
              const SizedBox(width: 6),
              const Text(
                'Loyalty Overview',
                style: TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${summary.businessCount} ${summary.businessCount == 1 ? 'business' : 'businesses'}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _LoyaltyStat(
                label: 'Earned',
                value: summary.totalEarned,
                color: AppColors.success,
              ),
              _LoyaltyStat(
                label: 'Spent',
                value: summary.totalSpent,
                color: AppColors.accent,
              ),
              _LoyaltyStat(
                label: 'Expired',
                value: summary.totalExpired,
                color: AppColors.warning,
              ),
              _LoyaltyStat(
                label: 'Available',
                value: summary.availablePoints,
                color: AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoyaltyStat extends StatelessWidget {
  const _LoyaltyStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            _fmt(value),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _MembershipTile extends StatelessWidget {
  const _MembershipTile({required this.membership});
  final BusinessMembershipSummaryDto membership;

  @override
  Widget build(BuildContext context) {
    final isAdmin =
        membership.role.toUpperCase().contains('BUSINESS_ADMIN');
    final color = isAdmin ? AppColors.accent : AppColors.gold;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isAdmin ? Icons.business_center_rounded : Icons.badge_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              membership.businessName,
              style: const TextStyle(
                color: AppColors.textOnDark,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              membership.role
                  .replaceAll('ROLE_', '')
                  .replaceAll('BUSINESS_ADMIN', 'ADMIN'),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_search_rounded,
            size: 64,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No users found' : 'No results for "$query"',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 56,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load users',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
