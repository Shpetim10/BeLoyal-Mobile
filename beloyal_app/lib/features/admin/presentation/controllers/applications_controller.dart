import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/admin_repository.dart';
import '../../domain/models/business_application.dart';
import '../../../business_onboarding/data/models/submit_application_models.dart';

enum ApplicationFilter { pending, all }

enum ApplicationSort { newest, oldest, nameAZ }

class AppSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;
}

final appSearchQueryProvider = NotifierProvider<AppSearchQueryNotifier, String>(
  AppSearchQueryNotifier.new,
);

class AppFilterNotifier extends Notifier<ApplicationFilter> {
  @override
  ApplicationFilter build() => ApplicationFilter.pending;

  void updateFilter(ApplicationFilter value) => state = value;
}

final appFilterProvider =
    NotifierProvider<AppFilterNotifier, ApplicationFilter>(
      AppFilterNotifier.new,
    );

class AppSortNotifier extends Notifier<ApplicationSort> {
  @override
  ApplicationSort build() => ApplicationSort.newest;

  void updateSort(ApplicationSort value) => state = value;
}

final appSortProvider = NotifierProvider<AppSortNotifier, ApplicationSort>(
  AppSortNotifier.new,
);

/// Manages fetching the list of business applications.
class ApplicationsController extends AsyncNotifier<List<BusinessApplication>> {
  @override
  Future<List<BusinessApplication>> build() async {
    return _fetchApplications();
  }

  Future<List<BusinessApplication>> _fetchApplications() async {
    return ref.read(adminRepositoryProvider).fetchPendingApplications();
  }

  /// Manually trigger a refresh.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchApplications);
  }

  /// Approve an application
  Future<String?> approve(int businessId) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.approveApplication(businessId);

      // Update local state if successful
      if (state.value != null) {
        final currentList = [...state.value!];
        final index = currentList.indexWhere((app) => app.id == businessId);
        if (index != -1) {
          // You either replace or remove. Since this is a "pending" list,
          // usually approval removes it from view.
          currentList.removeAt(index);
          state = AsyncData(currentList);
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Reject an application
  Future<String?> reject(int businessId, String reason) async {
    try {
      final repo = ref.read(adminRepositoryProvider);
      await repo.rejectApplication(businessId, reason);

      // Update local state if successful
      if (state.value != null) {
        final currentList = [...state.value!];
        final index = currentList.indexWhere((app) => app.id == businessId);
        if (index != -1) {
          // Remove from the pending list
          currentList.removeAt(index);
          state = AsyncData(currentList);
        }
      }
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final applicationsControllerProvider =
    AsyncNotifierProvider<ApplicationsController, List<BusinessApplication>>(
      ApplicationsController.new,
    );

final filteredSortedApplicationsProvider = Provider<List<BusinessApplication>>((
  ref,
) {
  final appsList = ref.watch(applicationsControllerProvider).value ?? [];
  final q = ref.watch(appSearchQueryProvider).toLowerCase().trim();
  final filter = ref.watch(appFilterProvider);
  final sort = ref.watch(appSortProvider);

  // 1. Filter
  var result = appsList.where((app) {
    if (filter == ApplicationFilter.pending &&
        app.businessStatus != BusinessStatus.pendingApproval) {
      return false;
    }

    if (q.isNotEmpty) {
      final n = app.businessName.toLowerCase();
      final e = app.businessEmail.toLowerCase();
      final p = (app.businessPhoneNumber ?? '').toLowerCase();
      final c = app.city.toLowerCase();

      if (!n.contains(q) &&
          !e.contains(q) &&
          !p.contains(q) &&
          !c.contains(q)) {
        return false;
      }
    }
    return true;
  }).toList();

  // 2. Sort
  result.sort((a, b) {
    switch (sort) {
      case ApplicationSort.newest:
        final da = a.submittedAt ?? DateTime(1970);
        final db = b.submittedAt ?? DateTime(1970);
        return db.compareTo(da);
      case ApplicationSort.oldest:
        final da = a.submittedAt ?? DateTime(1970);
        final db = b.submittedAt ?? DateTime(1970);
        return da.compareTo(db);
      case ApplicationSort.nameAZ:
        return a.businessName.toLowerCase().compareTo(
          b.businessName.toLowerCase(),
        );
    }
  });

  return result;
});

final pendingCountProvider = Provider<int>((ref) {
  final list = ref.watch(applicationsControllerProvider).value ?? [];
  return list
      .where((m) => m.businessStatus == BusinessStatus.pendingApproval)
      .length;
});
