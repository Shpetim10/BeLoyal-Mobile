import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/repositories/staff_repository.dart';
import '../../domain/models/staff_member.dart';

enum StaffFilter { all, active, inactive, invited }

enum StaffSort { nameAZ, lastLogin, newestAdded }

class StaffSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void updateQuery(String value) => state = value;
}

final staffSearchQueryProvider =
    NotifierProvider<StaffSearchQueryNotifier, String>(
      StaffSearchQueryNotifier.new,
    );

class StaffFilterNotifier extends Notifier<StaffFilter> {
  @override
  StaffFilter build() => StaffFilter.all;

  void updateFilter(StaffFilter value) => state = value;
}

final staffFilterProvider = NotifierProvider<StaffFilterNotifier, StaffFilter>(
  StaffFilterNotifier.new,
);

class StaffSortNotifier extends Notifier<StaffSort> {
  @override
  StaffSort build() => StaffSort.nameAZ;

  void updateSort(StaffSort value) => state = value;
}

final staffSortProvider = NotifierProvider<StaffSortNotifier, StaffSort>(
  StaffSortNotifier.new,
);

/// Provides the raw list of staff members for the active business.
final staffControllerProvider =
    AsyncNotifierProvider<StaffController, List<StaffMember>>(
      StaffController.new,
    );

class StaffController extends AsyncNotifier<List<StaffMember>> {
  StaffRepository get _repo => ref.read(staffRepositoryProvider);

  int? get _businessId => ref.read(sessionControllerProvider)?.activeBusinessId;

  @override
  Future<List<StaffMember>> build() async {
    final bId = _businessId;
    if (bId == null) return [];
    return _repo.fetchStaff(bId);
  }

  /// Force re-fetch from server.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build());
  }

  Future<String?> inviteStaff({
    required String email,
    DateTime? hireDate,
    String role = 'STAFF',
  }) async {
    final bId = _businessId;
    if (bId == null) return 'No active business selected.';

    // Optimistic: add a placeholder member immediately
    final placeholder = StaffMember(
      id: -DateTime.now().millisecondsSinceEpoch, // temp negative id
      email: email,
      hireDate: hireDate,
      memberStatus: MemberStatus.invited,
    );
    final previous = state.value ?? [];
    state = AsyncData([placeholder, ...previous]);

    try {
      await _repo.inviteStaff(
        bId,
        email: email,
        hireDate: hireDate,
        role: role,
      );
      // Keep optimistic placeholder until next refresh
      return null; // success
    } catch (e) {
      // Rollback
      state = AsyncData(previous);
      return e.toString();
    }
  }

  Future<String?> updateStatus(int memberId, MemberStatus newStatus) async {
    final bId = _businessId;
    if (bId == null) return 'No active business selected.';

    final previous = state.value ?? [];
    // Optimistic update
    state = AsyncData(
      previous
          .map(
            (m) => m.id == memberId ? m.copyWith(memberStatus: newStatus) : m,
          )
          .toList(),
    );

    try {
      await _repo.updateMemberStatus(bId, memberId, newStatus);
      return null;
    } catch (e) {
      // Rollback
      state = AsyncData(previous);
      return e.toString();
    }
  }

  Future<String?> resendInvite(int memberId) async {
    // For now, treat as a status update to re-trigger the invite
    return updateStatus(memberId, MemberStatus.invited);
  }
}

/// Filtered + sorted staff list.
final filteredStaffProvider = Provider<AsyncValue<List<StaffMember>>>((ref) {
  final staffAsync = ref.watch(staffControllerProvider);
  final query = ref.watch(staffSearchQueryProvider).toLowerCase();
  final filter = ref.watch(staffFilterProvider);
  final sort = ref.watch(staffSortProvider);

  return staffAsync.whenData((list) {
    var filtered = list.where((m) {
      // Status filter
      if (filter != StaffFilter.all) {
        final target = switch (filter) {
          StaffFilter.active => MemberStatus.active,
          StaffFilter.inactive => MemberStatus.inactive,
          StaffFilter.invited => MemberStatus.invited,
          StaffFilter.all => MemberStatus.active, // unreachable
        };
        if (m.memberStatus != target) return false;
      }

      // Search
      if (query.isNotEmpty) {
        final name = m.fullName.toLowerCase();
        final email = (m.email ?? '').toLowerCase();
        if (!name.contains(query) && !email.contains(query)) return false;
      }

      return true;
    }).toList();

    // Sort
    switch (sort) {
      case StaffSort.nameAZ:
        filtered.sort(
          (a, b) =>
              a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      case StaffSort.lastLogin:
        filtered.sort((a, b) {
          final aLogin = a.lastLogin ?? DateTime(1970);
          final bLogin = b.lastLogin ?? DateTime(1970);
          return bLogin.compareTo(aLogin); // most recent first
        });
      case StaffSort.newestAdded:
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }

    return filtered;
  });
});

/// Summary counts for the stat cards.
class StaffSummary {
  const StaffSummary({
    this.total = 0,
    this.active = 0,
    this.inactive = 0,
    this.pending = 0,
  });
  final int total;
  final int active;
  final int inactive;
  final int pending;
}

final staffSummaryProvider = Provider<StaffSummary>((ref) {
  final list = ref.watch(staffControllerProvider).value ?? [];
  return StaffSummary(
    total: list.length,
    active: list.where((m) => m.memberStatus == MemberStatus.active).length,
    inactive: list.where((m) => m.memberStatus == MemberStatus.inactive).length,
    pending: list.where((m) => m.memberStatus == MemberStatus.invited).length,
  );
});
