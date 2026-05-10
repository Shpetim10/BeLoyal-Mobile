import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:besahub_app/core/theme/app_colors.dart';
import 'package:besahub_app/core/theme/app_typography.dart';
import 'package:besahub_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:besahub_app/features/customer_loyalty/presentation/controllers/loyalty_card_provider.dart';
import 'package:besahub_app/features/customer_ui/data/providers/customer_providers.dart';
import 'package:besahub_app/features/customer_ui/presentation/widgets/customer_async_state.dart';

class CustomerProfileTab extends ConsumerWidget {
  const CustomerProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerData = ref.watch(customerDataProvider);
    final loyaltyCard = ref.watch(loyaltyCardProvider).asData?.value;
    return customerData.when(
      loading: () => const CustomerLoadingState(),
      error: (_, __) => CustomerErrorState(
        onRetry: () => ref.read(customerDataProvider.notifier).refresh(),
      ),
      data: (data) {
        final customer = data.summary;
        final displayName =
            [
                  loyaltyCard?.firstName ?? customer.firstName,
                  loyaltyCard?.lastName ?? customer.lastName,
                ]
                .whereType<String>()
                .where((part) => part.trim().isNotEmpty)
                .join(' ')
                .trim();
        final displayInitials = displayName.isNotEmpty
            ? displayName
                  .split(' ')
                  .where((part) => part.isNotEmpty)
                  .take(2)
                  .map((part) => part[0].toUpperCase())
                  .join()
            : customer.initials;
        final displayMemberCode = loyaltyCard?.manualCode.isNotEmpty == true
            ? loyaltyCard!.manualCode
            : customer.memberCode;
        final displayEmail = customer.email.isNotEmpty
            ? customer.email
            : 'Not available';
        final displayPhone = customer.phone.isNotEmpty
            ? customer.phone
            : 'Not available';

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHero(
                customer: customer,
                displayName: displayName.isNotEmpty ? displayName : 'Customer',
                displayInitials: displayInitials,
                displayEmail: displayEmail,
                displayMemberCode: displayMemberCode.isNotEmpty
                    ? displayMemberCode
                    : 'Unavailable',
              ),
              const SizedBox(height: 20),
              _FancyStatsCard(customer: customer),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Account'),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Personal Info',
                    subtitle: 'Name, gender, birthday',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.phone_outlined,
                    label: 'Phone Number',
                    subtitle: displayPhone,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.email_outlined,
                    label: 'Email Address',
                    subtitle: displayEmail,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.lock_outline_rounded,
                    label: 'Change Password',
                    subtitle: 'Update your password',
                    onTap: () {},
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
                    subtitle: 'Push, email, SMS',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.location_on_outlined,
                    label: 'Location Services',
                    subtitle: 'For nearby deals',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.language_rounded,
                    label: 'Language',
                    subtitle: 'English',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.dark_mode_outlined,
                    label: 'Appearance',
                    subtitle: 'Dark mode',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Saved'),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.home_outlined,
                    label: 'Saved Addresses',
                    subtitle: 'Coming soon',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.credit_card_outlined,
                    label: 'Payment Methods',
                    subtitle: 'Coming soon',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Favourite Businesses',
                    subtitle: 'Coming soon',
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionLabel(label: 'Support'),
              _SettingsGroup(
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Help Centre',
                    subtitle: 'FAQs and support',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    subtitle: 'How we use your data',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    subtitle: 'Usage agreement',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.info_outline_rounded,
                    label: 'App Version',
                    subtitle: 'BeLoyal',
                    onTap: null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _LogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}

// ─── Profile Hero ─────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.customer,
    required this.displayName,
    required this.displayInitials,
    required this.displayEmail,
    required this.displayMemberCode,
  });
  final dynamic customer;
  final String displayName;
  final String displayInitials;
  final String displayEmail;
  final String displayMemberCode;

  @override
  Widget build(BuildContext context) {
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
              // Avatar
              Container(
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
                child: Center(
                  child: Text(
                    displayInitials,
                    style: AppTypography.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
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
                                customer.memberSince.isNotEmpty
                                    ? 'Member since ${customer.memberSince}'
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
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Member code row
          GestureDetector(
            onTap: () {
              final memberCode = displayMemberCode;
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Member Code',
                    style: AppTypography.dmSans(
                      fontSize: 12,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    displayMemberCode,
                    style: AppTypography.dmMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    color: AppColors.primary,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          // Roles
          if ((customer.roles as List).length > 1) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Roles:',
                  style: AppTypography.dmSans(
                    fontSize: 12,
                    color: AppColors.textMutedDark,
                  ),
                ),
                const SizedBox(width: 8),
                ...(customer.roles as List<String>).map(
                  (r) => Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      r,
                      style: AppTypography.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Fancy Stats Card ─────────────────────────────────────────────────────────

class _FancyStatsCard extends StatelessWidget {
  const _FancyStatsCard({required this.customer});
  final dynamic customer;

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
                          'Since ${customer.memberSince}',
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
                          value: '${customer.lifetimePoints}',
                          color: AppColors.gold,
                          icon: Icons.stars_rounded,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Current\nBalance',
                          value: '${customer.currentPoints}',
                          color: AppColors.primary,
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Points\nSpent',
                          value: '${customer.spentPoints}',
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
                          value: '${customer.businessesVisited}',
                          color: AppColors.secondary,
                          icon: Icons.storefront_rounded,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Active\nCoupons',
                          value: '${customer.activeCoupons}',
                          color: AppColors.success,
                          icon: Icons.confirmation_number_rounded,
                        ),
                        _StatDivider(),
                        _StatBlock(
                          label: 'Active\nRewards',
                          value: '${customer.activeRewards}',
                          color: AppColors.gold,
                          icon: Icons.card_giftcard_rounded,
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
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.dmSans(
                      fontSize: 11,
                      color: AppColors.textMutedDark,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textMutedDark,
              ),
          ],
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
      child: GestureDetector(
        onTap: () => ref.read(authControllerProvider).logout(),
        child: Container(
          height: 52,
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
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Log Out',
                style: AppTypography.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
