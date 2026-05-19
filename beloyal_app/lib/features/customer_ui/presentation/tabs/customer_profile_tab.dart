import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/core/widgets/besa_loader.dart';
import 'package:besahub_app/features/auth/domain/models/auth_user.dart';
import 'package:besahub_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:besahub_app/features/auth/presentation/controllers/session_controller.dart';
import 'package:besahub_app/features/customer_ui/data/models/customer_home_dto.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';
import 'package:besahub_app/features/media/data/repositories/media_repository.dart';
import 'package:besahub_app/features/profile/data/repositories/profile_repository.dart';
import 'package:besahub_app/features/profile/presentation/pages/change_password_page.dart';

// ignore_for_file: use_build_context_synchronously

class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(customerProfileDetailsProvider);
    return profileAsync.when(
      loading: () => const CustomerLoadingState(),
      error: (_, __) => CustomerErrorState(
        onRetry: () =>
            ref.read(customerProfileDetailsProvider.notifier).refresh(),
      ),
      data: (details) {
        final profile = details.profile;
        final stats = details.stats;
        final displayPhone = profile.phoneNumber?.isNotEmpty == true
            ? profile.phoneNumber!
            : 'Not available';
        final displayEmail = profile.email.isNotEmpty
            ? profile.email
            : 'Not available';

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () =>
              ref.read(customerProfileDetailsProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHero(
                  profile: profile,
                  displayEmail: displayEmail,
                  onEditTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _CustomerProfileEditPage(details: details),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _FancyStatsCard(stats: stats),
                const SizedBox(height: 20),
                _SectionLabel(label: 'Account'),
                _SettingsGroup(
                  items: [
                    _SettingsItem(
                      icon: Icons.person_outline_rounded,
                      label: 'Personal Info',
                      subtitle: 'Name, username, gender, birthdate',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CustomerProfileInfoPage(
                            title: 'Personal Info',
                            fields: [
                              _InfoField(
                                'First Name',
                                profile.firstName.isNotEmpty
                                    ? profile.firstName
                                    : '—',
                              ),
                              _InfoField(
                                'Last Name',
                                profile.lastName.isNotEmpty
                                    ? profile.lastName
                                    : '—',
                              ),
                              _InfoField(
                                'Username',
                                profile.username.isNotEmpty
                                    ? profile.username
                                    : '—',
                              ),
                              _InfoField(
                                'Gender',
                                profile.gender?.isNotEmpty == true
                                    ? profile.gender!
                                    : '—',
                              ),
                              _InfoField(
                                'Birthdate',
                                profile.birthDate?.isNotEmpty == true
                                    ? profile.birthDate!
                                    : '—',
                              ),
                            ],
                            onEditTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _CustomerProfileEditPage(
                                  details: details,
                                  section: _ProfileEditSection.personal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.contact_phone_outlined,
                      label: 'Contact Info',
                      subtitle: 'Email, phone, city, country',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CustomerProfileInfoPage(
                            title: 'Contact Info',
                            fields: [
                              _InfoField('Email', displayEmail),
                              _InfoField('Phone', displayPhone),
                              _InfoField(
                                'City',
                                profile.city?.isNotEmpty == true
                                    ? profile.city!
                                    : '—',
                              ),
                              _InfoField(
                                'Country',
                                profile.country?.isNotEmpty == true
                                    ? profile.country!
                                    : '—',
                              ),
                            ],
                            onEditTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _CustomerProfileEditPage(
                                  details: details,
                                  section: _ProfileEditSection.contact,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.badge_outlined,
                      label: 'Membership & Referrals',
                      subtitle: 'Member details and referral info',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CustomerProfileInfoPage(
                            title: 'Membership & Referrals',
                            fields: [
                              _InfoField(
                                'Status',
                                profile.status.isNotEmpty
                                    ? profile.status
                                    : '—',
                              ),
                              _InfoField(
                                'Member Since',
                                profile.memberSince.isNotEmpty
                                    ? profile.memberSince
                                    : '—',
                              ),
                              _InfoField(
                                'Member Code',
                                profile.memberCode.isNotEmpty
                                    ? profile.memberCode
                                    : '—',
                              ),
                              _InfoField(
                                'Terms Accepted',
                                profile.acceptedTerms ? 'Yes' : 'No',
                              ),
                              _InfoField(
                                'Referral Code',
                                profile.referralCode?.isNotEmpty == true
                                    ? profile.referralCode!
                                    : '—',
                              ),
                              _InfoField(
                                'Referred By',
                                profile.referredBy?.isNotEmpty == true
                                    ? profile.referredBy!
                                    : '—',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    _SettingsItem(
                      icon: Icons.lock_outline_rounded,
                      label: 'Change Password',
                      subtitle: 'Update your password',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionLabel(label: 'Preferences'),
                _SettingsGroup(
                  items: [
                    _SettingsItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      subtitle: profile.notificationEnabled
                          ? 'Notifications on'
                          : 'Notifications off',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => _CustomerNotificationsPage(
                            enabled: profile.notificationEnabled,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _LogoutButton(),
                const SizedBox(height: 12),
                const _DeleteAccountButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.displayEmail,
    required this.onEditTap,
  });
  final CustomerProfileHeaderDto profile;
  final String displayEmail;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    final displayName = profile.fullName.isNotEmpty
        ? profile.fullName
        : 'Customer';
    final memberCode = profile.memberCode.isNotEmpty
        ? profile.memberCode
        : 'Unavailable';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _AvatarWidget(
                imageUrl: profile.profileImageUrl,
                initials: profile.avatarInitials.isNotEmpty
                    ? profile.avatarInitials
                    : '?',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: AppTypography.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayEmail,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.loyalty_rounded,
                                color: AppColors.primary,
                                size: 11,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                profile.memberSince.isNotEmpty
                                    ? 'Member since ${profile.memberSince}'
                                    : 'Loyalty member',
                                style: AppTypography.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onEditTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.edit_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Member code row
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: memberCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Member code copied!',
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: AppColors.surfaceDark,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.elevDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.badge_outlined,
                      color: AppColors.textMutedDark,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Member Code',
                      style: AppTypography.dmSans(
                        fontSize: 13,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      memberCode,
                      style: AppTypography.dmMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.copy_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar Widget ────────────────────────────────────────────────────────────

class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({required this.imageUrl, required this.initials});
  final String? imageUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
            AppColors.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: hasImage
          ? ClipOval(
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                width: 72,
                height: 72,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    initials,
                    style: AppTypography.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                initials,
                style: AppTypography.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }
}

// ─── Fancy Stats Card ─────────────────────────────────────────────────────────

class _FancyStatsCard extends StatelessWidget {
  const _FancyStatsCard({required this.stats});
  final CustomerSummaryDto stats;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F0D1A), Color(0xFF1A0535), Color(0xFF2D1060)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.glassBorderStrong),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                bottom: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_graph_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Loyalty Stats',
                          style: AppTypography.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textOnDark,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Since ${stats.memberSinceLabel}',
                          style: AppTypography.dmSans(
                            fontSize: 10,
                            color: AppColors.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _StatBlock(
                          label: 'Lifetime\nPoints',
                          value: '${stats.lifetimePoints}',
                          color: AppColors.gold,
                          icon: Icons.stars_rounded,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Current\nBalance',
                          value: '${stats.currentPoints}',
                          color: AppColors.primary,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Points\nSpent',
                          value: '${stats.spentPoints}',
                          color: AppColors.accent,
                          icon: Icons.redeem_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Divider(color: AppColors.glassBorder, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatBlock(
                          label: 'Businesses\nVisited',
                          value: '${stats.businessesVisited}',
                          color: AppColors.secondary,
                          icon: Icons.storefront_rounded,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Active\nCoupons',
                          value: '${stats.activeCoupons}',
                          color: AppColors.success,
                          icon: Icons.confirmation_number_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.dmMono(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textOnDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 10,
              color: AppColors.textMutedDark,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 60, color: AppColors.glassBorder);
  }
}

// ─── Settings ─────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.overline(color: AppColors.textMutedDark),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.items});
  final List<_SettingsItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 56, color: AppColors.glassBorder),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textOnDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.textMutedDark,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 12),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppColors.textMutedDark,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(authControllerProvider).logout(),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  'Log Out',
                  style: AppTypography.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteAccountButton extends ConsumerWidget {
  const _DeleteAccountButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDeleteDialog(context, ref),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Delete Account',
                  style: AppTypography.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'Delete Customer Account',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will permanently delete all your loyalty data including:\n\n'
          '• All loyalty cards and points\n'
          '• All point transactions\n'
          '• All coupon redemptions\n\n'
          'Your business admin membership and business data will be preserved. '
          'This action cannot be undone.',
          style: TextStyle(color: AppColors.textMuted, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final profileRepo = ref.read(profileRepositoryProvider);
    final result = await profileRepo.deleteCustomerAccount();

    if (!context.mounted) return;

    switch (result) {
      case AuthSuccess():
        final sessionNotifier = ref.read(sessionControllerProvider.notifier);
        sessionNotifier.removeCustomerRole();

        // Switch to a remaining role and navigate away from customer pages
        final updatedSession = ref.read(sessionControllerProvider);
        final user = updatedSession?.user;
        String? dashboardPath;
        if (user != null) {
          if (user.roles.contains(UserRole.superAdmin)) {
            sessionNotifier.switchRole(UserRole.superAdmin);
            dashboardPath = '/admin/dashboard';
          } else if (user.businessProfiles.isNotEmpty) {
            final firstProfile = user.businessProfiles.first;
            sessionNotifier.switchRole(
              firstProfile.role,
              businessId: firstProfile.businessId,
              businessName: firstProfile.businessName,
            );
            dashboardPath = firstProfile.role == UserRole.businessAdmin
                ? '/business/dashboard'
                : '/staff/dashboard';
          } else {
            ref.read(authControllerProvider).logout();
            return;
          }
        }

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer account deleted successfully',
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceDark,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        if (dashboardPath != null && context.mounted) {
          context.go(dashboardPath);
        }
      case AuthError(failure: final f):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              f.message,
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
    }
  }
}

// ─── Profile Info Field ───────────────────────────────────────────────────────

class _InfoField {
  const _InfoField(this.label, this.value);
  final String label;
  final String value;
}

// ─── Profile Info Page ────────────────────────────────────────────────────────

class _CustomerProfileInfoPage extends StatelessWidget {
  const _CustomerProfileInfoPage({
    required this.title,
    required this.fields,
    this.onEditTap,
  });
  final String title;
  final List<_InfoField> fields;
  final VoidCallback? onEditTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTypography.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
        actions: [
          if (onEditTap != null)
            IconButton(
              onPressed: onEditTap,
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < fields.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.glassBorder,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fields[i].label,
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          fields[i].value,
                          style: AppTypography.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textOnDark,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Profile Edit Page ────────────────────────────────────────────────────────

enum _ProfileEditSection { all, personal, contact, membership }

class _CustomerProfileEditPage extends ConsumerStatefulWidget {
  const _CustomerProfileEditPage({
    required this.details,
    this.section = _ProfileEditSection.all,
  });
  final CustomerProfileDetailsDto details;
  final _ProfileEditSection section;

  @override
  ConsumerState<_CustomerProfileEditPage> createState() =>
      _CustomerProfileEditPageState();
}

class _CustomerProfileEditPageState
    extends ConsumerState<_CustomerProfileEditPage> {
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _countryCtrl;
  String? _gender;
  DateTime? _birthDate;
  bool _saving = false;
  bool _uploadingImage = false;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    final p = widget.details.profile;
    _firstNameCtrl = TextEditingController(text: p.firstName);
    _lastNameCtrl = TextEditingController(text: p.lastName);
    _usernameCtrl = TextEditingController(text: p.username);
    _phoneCtrl = TextEditingController(text: p.phoneNumber ?? '');
    _cityCtrl = TextEditingController(text: p.city ?? '');
    _countryCtrl = TextEditingController(text: p.country ?? '');
    _gender = p.gender;
    _birthDate = p.birthDate == null ? null : DateTime.tryParse(p.birthDate!);
    _currentImageUrl = p.profileImageUrl;
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _showAvatarOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Profile Photo',
                    style: AppTypography.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textOnDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Choose from gallery',
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Take a photo',
                  style: AppTypography.dmSans(
                    fontSize: 14,
                    color: AppColors.textOnDark,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndUploadImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked == null) return;

      final ext = picked.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(ext)) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(_snackBar('Only JPG and PNG are allowed.', isError: true));
        }
        return;
      }

      setState(() => _uploadingImage = true);

      final session = ref.read(sessionControllerProvider);
      if (session == null) {
        if (mounted) setState(() => _uploadingImage = false);
        return;
      }

      final mediaRepo = ref.read(mediaRepositoryProvider);
      final uploadResult = await mediaRepo.uploadImage(
        file: picked,
        category: 'USER_PROFILE',
        ownerId: session.user.userId,
      );

      final url = uploadResult['url'];
      final key = uploadResult['key'];
      if (url == null || key == null) {
        throw Exception('Failed to retrieve image URL or key');
      }

      final profileRepo = ref.read(profileRepositoryProvider);
      await profileRepo.updateUserProfile(
        profileImageUrl: url,
        profileImageKey: key,
      );

      await ref.read(customerProfileDetailsProvider.notifier).refresh();

      if (mounted) {
        setState(() => _currentImageUrl = url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar('Profile photo updated.'));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            'Failed to update photo. Please try again.',
            isError: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<void> _save() async {
    final firstName = _firstNameCtrl.text.trim();
    if (firstName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snackBar('First name cannot be empty.', isError: true));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(customerProfileDetailsProvider.notifier)
          .updateProfile(
            firstName: firstName,
            lastName: _lastNameCtrl.text.trim(),
            username: _usernameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            city: _cityCtrl.text.trim(),
            country: _countryCtrl.text.trim(),
            gender: _gender,
            birthDate: _birthDate,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(_snackBar('Profile updated successfully.'));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          _snackBar(
            'Failed to update profile. Please try again.',
            isError: true,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  SnackBar _snackBar(String message, {bool isError = false}) {
    return SnackBar(
      content: Text(
        message,
        style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
      ),
      backgroundColor: isError ? AppColors.error : AppColors.surfaceDark,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.details.profile;
    final isAll = widget.section == _ProfileEditSection.all;
    final isPersonal = widget.section == _ProfileEditSection.personal;
    final isContact = widget.section == _ProfileEditSection.contact;
    final isMembership = widget.section == _ProfileEditSection.membership;
    final pageTitle = switch (widget.section) {
      _ProfileEditSection.all => 'Edit Profile',
      _ProfileEditSection.personal => 'Edit Personal Info',
      _ProfileEditSection.contact => 'Edit Contact Info',
      _ProfileEditSection.membership => 'Membership Details',
    };
    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          pageTitle,
          style: AppTypography.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: BesaLoader(size: 18),
                  )
                : GestureDetector(
                    onTap: _save,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Save',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tappable avatar with upload support
            Center(
              child: GestureDetector(
                onTap: _uploadingImage ? null : _showAvatarOptions,
                child: Stack(
                  children: [
                    _AvatarWidget(
                      imageUrl: _currentImageUrl,
                      initials: profile.avatarInitials.isNotEmpty
                          ? profile.avatarInitials
                          : '?',
                    ),
                    if (_uploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: const Center(child: BesaLoader(size: 24)),
                        ),
                      ),
                    if (!_uploadingImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF0A0812),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (isAll || isPersonal) ...[
              _EditSectionLabel(label: 'Personal Details'),
              const SizedBox(height: 12),
              _EditFieldCard(
                children: [
                  _EditFieldRow(
                    label: 'First Name',
                    controller: _firstNameCtrl,
                    hint: 'Enter first name',
                    textInputAction: TextInputAction.next,
                  ),
                  _EditFieldRow(
                    label: 'Last Name',
                    controller: _lastNameCtrl,
                    hint: 'Enter last name',
                    textInputAction: TextInputAction.next,
                  ),
                  _EditFieldRow(
                    label: 'Username',
                    controller: _usernameCtrl,
                    hint: 'Enter username',
                    textInputAction: TextInputAction.next,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _EditSectionLabel(label: 'Demographics'),
              const SizedBox(height: 12),
              _EditFieldCard(
                children: [
                  _EditDropdownFieldRow<String>(
                    label: 'Gender',
                    value: _gender,
                    hint: 'Select',
                    items: const [
                      DropdownMenuItem(value: 'MALE', child: Text('Male')),
                      DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
                      DropdownMenuItem(value: 'OTHER', child: Text('Other')),
                      DropdownMenuItem(
                        value: 'PREFER_NOT_TO_SAY',
                        child: Text('Prefer not to say'),
                      ),
                    ],
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  _EditActionFieldRow(
                    label: 'Birthdate',
                    value: _birthDate == null
                        ? 'Select date'
                        : '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}',
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _birthDate ?? DateTime(now.year - 25),
                        firstDate: DateTime(1900),
                        lastDate: now,
                      );
                      if (picked != null) {
                        setState(() => _birthDate = picked);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            if (isAll || isContact) ...[
              _EditSectionLabel(label: 'Contact'),
              const SizedBox(height: 12),
              _EditFieldCard(
                children: [
                  _EditFieldRow(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    hint: 'Enter phone number',
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                  ),
                  _EditFieldRow(
                    label: 'City',
                    controller: _cityCtrl,
                    hint: 'Enter city',
                    textInputAction: TextInputAction.next,
                  ),
                  _EditFieldRow(
                    label: 'Country',
                    controller: _countryCtrl,
                    hint: 'Enter country',
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            _EditSectionLabel(label: 'Read-Only'),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  _ReadOnlyRow(
                    label: 'Email',
                    value: profile.email.isNotEmpty ? profile.email : '—',
                  ),
                  Divider(height: 1, color: AppColors.glassBorder),
                  _ReadOnlyRow(
                    label: 'Status',
                    value: profile.status.isNotEmpty ? profile.status : '—',
                  ),
                  Divider(height: 1, color: AppColors.glassBorder),
                  _ReadOnlyRow(
                    label: 'Member Code',
                    value: profile.memberCode.isNotEmpty
                        ? profile.memberCode
                        : '—',
                  ),
                  Divider(height: 1, color: AppColors.glassBorder),
                  _ReadOnlyRow(
                    label: 'Member Since',
                    value: profile.memberSince.isNotEmpty
                        ? profile.memberSince
                        : '—',
                  ),
                  if (isAll || isMembership) ...[
                    Divider(height: 1, color: AppColors.glassBorder),
                    _ReadOnlyRow(
                      label: 'Referral Code',
                      value: profile.referralCode?.isNotEmpty == true
                          ? profile.referralCode!
                          : '—',
                    ),
                    Divider(height: 1, color: AppColors.glassBorder),
                    _ReadOnlyRow(
                      label: 'Referred By',
                      value: profile.referredBy?.isNotEmpty == true
                          ? profile.referredBy!
                          : '—',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.info,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To change your email address, please contact support.',
                      style: AppTypography.dmSans(
                        fontSize: 12,
                        color: AppColors.info,
                        height: 1.5,
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
}

class _EditSectionLabel extends StatelessWidget {
  const _EditSectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.overline(color: AppColors.textMutedDark),
    );
  }
}

class _EditFieldCard extends StatelessWidget {
  const _EditFieldCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(
          const Divider(height: 1, thickness: 1, color: AppColors.glassBorder),
        );
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(children: rows),
    );
  }
}

class _EditFieldRow extends StatelessWidget {
  const _EditFieldRow({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textInputAction,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.textMutedDark,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType ?? TextInputType.text,
              textInputAction: textInputAction,
              style: AppTypography.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textOnDark,
              ),
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTypography.dmSans(
                  fontSize: 13,
                  color: AppColors.textMutedDark.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              cursorColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditDropdownFieldRow<T> extends StatelessWidget {
  const _EditDropdownFieldRow({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTypography.dmSans(
                fontSize: 12,
                color: AppColors.textMutedDark,
              ),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<T>(
              initialValue: value,
              hint: Text(hint),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              dropdownColor: AppColors.surfaceDark,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditActionFieldRow extends StatelessWidget {
  const _EditActionFieldRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              child: Text(
                label,
                style: AppTypography.dmSans(
                  fontSize: 12,
                  color: AppColors.textMutedDark,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: AppTypography.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnDark,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.calendar_month_rounded,
              size: 14,
              color: AppColors.textMutedDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: AppTypography.dmSans(
              fontSize: 13,
              color: AppColors.textMutedDark,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: AppTypography.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.lock_outline_rounded,
            size: 12,
            color: AppColors.textMutedDark,
          ),
        ],
      ),
    );
  }
}

// ─── Notifications Page ───────────────────────────────────────────────────────

class _CustomerNotificationsPage extends ConsumerStatefulWidget {
  const _CustomerNotificationsPage({required this.enabled});
  final bool enabled;

  @override
  ConsumerState<_CustomerNotificationsPage> createState() =>
      _CustomerNotificationsPageState();
}

class _CustomerNotificationsPageState
    extends ConsumerState<_CustomerNotificationsPage> {
  late bool _enabled;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled;
  }

  Future<void> _toggle(bool value) async {
    setState(() {
      _enabled = value;
      _saving = true;
    });
    try {
      await ref
          .read(customerProfileDetailsProvider.notifier)
          .updateNotificationEnabled(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Notifications enabled.' : 'Notifications disabled.',
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.surfaceDark,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _enabled = !value);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update notifications. Please try again.',
              style: AppTypography.dmSans(fontSize: 13, color: Colors.white),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0812),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0812),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Notifications',
          style: AppTypography.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textOnDark,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push Notifications',
                        style: AppTypography.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      Text(
                        'Receive alerts for rewards, offers & activity',
                        style: AppTypography.dmSans(
                          fontSize: 11,
                          color: AppColors.textMutedDark,
                        ),
                      ),
                    ],
                  ),
                ),
                _saving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: BesaLoader(size: 20),
                      )
                    : Switch(
                        value: _enabled,
                        onChanged: _toggle,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primary.withValues(
                          alpha: 0.4,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
