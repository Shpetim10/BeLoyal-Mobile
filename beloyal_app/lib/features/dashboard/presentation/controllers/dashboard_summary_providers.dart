import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/dashboard_summary_dtos.dart';
import '../../data/repositories/dashboard_repository.dart';

/// Business admin dashboard summary — family keyed by businessId.
final businessDashboardSummaryProvider = FutureProvider.family<
    BusinessDashboardSummaryDto, int>((ref, businessId) async {
  if (businessId == 0) throw Exception('No active business');
  return ref.read(dashboardRepositoryProvider).fetchBusinessSummary(businessId);
});

/// Staff dashboard summary — family keyed by businessId.
final staffDashboardSummaryProvider = FutureProvider.family<
    StaffDashboardSummaryDto, int>((ref, businessId) async {
  if (businessId == 0) throw Exception('No active business');
  return ref.read(dashboardRepositoryProvider).fetchStaffSummary(businessId);
});

/// Super admin platform summary.
final adminPlatformSummaryProvider =
    FutureProvider<AdminPlatformSummaryDto>((ref) async {
  return ref.read(dashboardRepositoryProvider).fetchPlatformSummary();
});
