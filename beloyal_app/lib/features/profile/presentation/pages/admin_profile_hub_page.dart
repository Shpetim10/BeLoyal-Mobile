import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import './my_profile_tab.dart';
import './business_profile_tab.dart';

/// Admin Profile Hub Page — two-tab interface for Business Admins.
///
/// Tab 1: "My Profile" — personal account details, avatar, change password.
/// Tab 2: "Restaurant Profile" — business branding, location, contact details.
///
/// Route: /admin/profile
class AdminProfileHubPage extends ConsumerStatefulWidget {
  const AdminProfileHubPage({super.key, this.initialTab = 0});

  /// Allows jumping directly to Tab 1 (Restaurant Profile) from deep links.
  final int initialTab;

  @override
  ConsumerState<AdminProfileHubPage> createState() =>
      _AdminProfileHubPageState();
}

class _AdminProfileHubPageState extends ConsumerState<AdminProfileHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final isBusinessAdmin = session?.activeRole == UserRole.businessAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _buildTabBar(isBusinessAdmin),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const MyProfileTab(),
          if (isBusinessAdmin) const BusinessProfileTab(),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isBusinessAdmin) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.glassWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.glassBorder.withValues(alpha: 0.4)),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textMuted,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: _tabController.index == 0
                      ? Colors.white
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                const Text('My Profile'),
              ],
            ),
          ),
          if (isBusinessAdmin)
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.store_rounded,
                    size: 16,
                    color: _tabController.index == 1
                        ? Colors.white
                        : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  const Text('Restaurant'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
