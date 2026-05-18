import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/besa_loader.dart';
import '../../../dashboard/data/models/dashboard_summary_dtos.dart';
import '../../../dashboard/presentation/controllers/dashboard_summary_providers.dart';

class AdminMonitoringPage extends ConsumerWidget {
  const AdminMonitoringPage({super.key});

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
            // ── Live health banner ───────────────────────────────────────────
            summaryAsync.when(
              loading: () => _HealthBanner(health: null),
              error: (_, __) => _HealthBanner(health: null),
              data: (s) => _HealthBanner(health: s.health),
            ),
            const SizedBox(height: 20),

            // ── System Services ──────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.dns_rounded,
              label: 'System Services',
              iconColor: AppColors.accent,
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => _ServiceGrid(health: null),
              error: (_, __) => _ServiceGrid(health: null),
              data: (s) => _ServiceGrid(health: s.health),
            ),
            const SizedBox(height: 24),

            // ── Platform Stats ───────────────────────────────────────────────
            _SectionHeader(
              icon: Icons.analytics_rounded,
              label: 'Platform Statistics',
              iconColor: AppColors.gold,
            ),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => _PlatformStatsSection(summary: null),
              error: (e, _) => _RetryCard(
                message: e.toString(),
                onRetry: () => ref.invalidate(adminPlatformSummaryProvider),
              ),
              data: (s) => _PlatformStatsSection(summary: s),
            ),
            const SizedBox(height: 24),

            // ── Refresh timestamp ─────────────────────────────────────────────
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Last refreshed: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Health Banner ─────────────────────────────────────────────────────────────

class _HealthBanner extends StatelessWidget {
  const _HealthBanner({required this.health});
  final PlatformHealthDto? health;

  @override
  Widget build(BuildContext context) {
    final isUp = health?.isUp ?? true;
    final statusText = health == null
        ? 'Loading…'
        : isUp
            ? 'All Systems Operational'
            : 'Degraded Performance Detected';
    final color = isUp ? AppColors.success : AppColors.error;
    final gradient = isUp
        ? [const Color(0xFF14532D), const Color(0xFF16A34A)]
        : [const Color(0xFF7F1D1D), AppColors.error];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 20,
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
            child: Icon(
              isUp
                  ? Icons.check_circle_outline_rounded
                  : Icons.warning_amber_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'BesaHub Platform • ${DateTime.now().year}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (health != null)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUp ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }
}

// ── Service Grid ──────────────────────────────────────────────────────────────

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({required this.health});
  final PlatformHealthDto? health;

  @override
  Widget build(BuildContext context) {
    final services = [
      (
        'Database',
        Icons.storage_rounded,
        health?.databaseUp ?? true,
        AppColors.primary,
      ),
      (
        'Redis Cache',
        Icons.bolt_rounded,
        health?.redisUp ?? true,
        AppColors.accent,
      ),
      (
        'Disk Space',
        Icons.disc_full_rounded,
        health?.diskSpaceUp ?? true,
        AppColors.gold,
      ),
      (
        'API Gateway',
        Icons.cloud_done_rounded,
        health?.isUp ?? true,
        AppColors.secondary,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: services
          .asMap()
          .entries
          .map(
            (e) => _ServiceCard(
              name: e.value.$1,
              icon: e.value.$2,
              isUp: e.value.$3,
              accentColor: e.value.$4,
              index: e.key,
            ),
          )
          .toList(),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({
    required this.name,
    required this.icon,
    required this.isUp,
    required this.accentColor,
    required this.index,
  });
  final String name;
  final IconData icon;
  final bool isUp;
  final Color accentColor;
  final int index;

  @override
  Widget build(BuildContext context) {
    final statusColor = isUp ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: statusColor,
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isUp ? 'Operational' : 'Down',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms + 100.ms)
        .fadeIn(duration: 350.ms)
        .scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}

// ── Platform Stats ────────────────────────────────────────────────────────────

class _PlatformStatsSection extends StatelessWidget {
  const _PlatformStatsSection({required this.summary});
  final AdminPlatformSummaryDto? summary;

  String _fmt(int? n) {
    if (n == null) return '—';
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'Total Businesses',
        _fmt(summary?.totalBusinesses),
        Icons.business_rounded,
        AppColors.primary,
        '${_fmt(summary?.activeBusinesses)} active',
      ),
      (
        'Pending Approvals',
        _fmt(summary?.pendingApplicationsCount),
        Icons.pending_actions_rounded,
        AppColors.warning,
        'Awaiting review',
      ),
      (
        'Registered Users',
        _fmt(summary?.registeredUsersCount),
        Icons.people_rounded,
        AppColors.secondary,
        'All roles',
      ),
    ];

    return Column(
      children: stats
          .asMap()
          .entries
          .map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _StatRow(
                label: e.value.$1,
                value: e.value.$2,
                icon: e.value.$3,
                color: e.value.$4,
                subtitle: e.value.$5,
                index: e.key,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.index,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    )
        .animate(delay: (index * 60).ms + 150.ms)
        .fadeIn(duration: 350.ms)
        .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}


// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
        const SizedBox(width: 7),
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

class _RetryCard extends StatelessWidget {
  const _RetryCard({required this.message, required this.onRetry});
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
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Could not load metrics',
              style: TextStyle(
                color: AppColors.textOnDark.withValues(alpha: 0.75),
                fontSize: 13,
              ),
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
