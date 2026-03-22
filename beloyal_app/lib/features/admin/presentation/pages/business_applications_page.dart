import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../controllers/applications_controller.dart';
import '../widgets/application_card.dart';
import '../widgets/application_empty_state.dart';
import '../widgets/application_search_bar.dart';

class BusinessApplicationsPage extends ConsumerWidget {
  const BusinessApplicationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsState = ref.watch(applicationsControllerProvider);
    final sortedList = ref.watch(filteredSortedApplicationsProvider);
    final pendingCount = ref.watch(pendingCountProvider);

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(applicationsControllerProvider.notifier).refresh(),
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceDark,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBarDelegate(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ApplicationSearchBar(),
                  // Small Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Applications: $pendingCount',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppColors.glassBorder),
                ],
              ),
            ),
          ),
          applicationsState.when(
            loading: () => SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: ApplicationEmptyState.error(
                error: err.toString(),
                onRetry: () =>
                    ref.read(applicationsControllerProvider.notifier).refresh(),
              ),
            ),
            data: (allApps) {
              if (allApps.isEmpty) {
                return SliverToBoxAdapter(
                  child: ApplicationEmptyState.noPending(
                    onRefresh: () => ref
                        .read(applicationsControllerProvider.notifier)
                        .refresh(),
                  ),
                );
              }

              if (sortedList.isEmpty) {
                return SliverToBoxAdapter(
                  child: ApplicationEmptyState.noResults(
                    onClearFilters: () {
                      ref.read(appSearchQueryProvider.notifier).updateQuery('');
                    },
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final app = sortedList[index];
                    return ApplicationCard(
                      application: app,
                      onTap: () {
                        // Navigate to details page
                        context.push('/admin/business-applications/${app.id}');
                      },
                    );
                  }, childCount: sortedList.length),
                ),
              );
            },
          ),

          // Extra padding at bottom for navbar
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchBarDelegate({required this.child});
  final Widget child;

  // Fixed height to avoid SliverGeometry assertion (exactly matches actual child height 110px)
  @override
  double get minExtent => 110.0;
  @override
  double get maxExtent => 110.0;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: AppColors.bgDark,
      child: SizedBox(
        height: 110.0,
        child: Align(alignment: Alignment.topCenter, child: child),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}
