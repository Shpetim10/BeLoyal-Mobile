// DTOs for the three dashboard summary endpoints.

// ── Business Admin ─────────────────────────────────────────────────────────────

class BusinessDashboardSummaryDto {
  const BusinessDashboardSummaryDto({
    required this.staffCount,
    required this.activeCouponsCount,
    required this.transactionsTotal,
    required this.loyalCustomersCount,
    required this.todayPointsIssued,
  });

  final int staffCount;
  final int activeCouponsCount;
  final int transactionsTotal;
  final int loyalCustomersCount;
  final int todayPointsIssued;

  factory BusinessDashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return BusinessDashboardSummaryDto(
      staffCount: (json['staffCount'] as num? ?? 0).toInt(),
      activeCouponsCount: (json['activeCouponsCount'] as num? ?? 0).toInt(),
      transactionsTotal: (json['transactionsTotal'] as num? ?? 0).toInt(),
      loyalCustomersCount: (json['loyalCustomersCount'] as num? ?? 0).toInt(),
      todayPointsIssued: (json['todayPointsIssued'] as num? ?? 0).toInt(),
    );
  }
}

// ── Staff ──────────────────────────────────────────────────────────────────────

class StaffDashboardSummaryDto {
  const StaffDashboardSummaryDto({
    required this.todayScansCount,
    required this.pendingRedemptionsCount,
    required this.activeCustomersCount,
    required this.transactionsCount,
  });

  final int todayScansCount;
  final int pendingRedemptionsCount;
  final int activeCustomersCount;
  final int transactionsCount;

  factory StaffDashboardSummaryDto.fromJson(Map<String, dynamic> json) {
    return StaffDashboardSummaryDto(
      todayScansCount: (json['todayScansCount'] as num? ?? 0).toInt(),
      pendingRedemptionsCount:
          (json['pendingRedemptionsCount'] as num? ?? 0).toInt(),
      activeCustomersCount:
          (json['activeCustomersCount'] as num? ?? 0).toInt(),
      transactionsCount: (json['transactionsCount'] as num? ?? 0).toInt(),
    );
  }
}

// ── Super Admin ────────────────────────────────────────────────────────────────

class AdminPlatformSummaryDto {
  const AdminPlatformSummaryDto({
    required this.totalBusinesses,
    required this.activeBusinesses,
    required this.pendingApplicationsCount,
    required this.registeredUsersCount,
    required this.health,
  });

  final int totalBusinesses;
  final int activeBusinesses;
  final int pendingApplicationsCount;
  final int registeredUsersCount;
  final PlatformHealthDto health;

  factory AdminPlatformSummaryDto.fromJson(Map<String, dynamic> json) {
    return AdminPlatformSummaryDto(
      totalBusinesses: (json['totalBusinesses'] as num? ?? 0).toInt(),
      activeBusinesses: (json['activeBusinesses'] as num? ?? 0).toInt(),
      pendingApplicationsCount:
          (json['pendingApplicationsCount'] as num? ?? 0).toInt(),
      registeredUsersCount:
          (json['registeredUsersCount'] as num? ?? 0).toInt(),
      health: PlatformHealthDto.fromJson(
        json['health'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PlatformHealthDto {
  const PlatformHealthDto({
    required this.status,
    required this.database,
    required this.redis,
    required this.diskSpace,
  });

  final String status;
  final String database;
  final String redis;
  final String diskSpace;

  bool get isUp => status.toUpperCase() == 'UP';
  bool get databaseUp => database.toUpperCase() == 'UP';
  bool get redisUp => redis.toUpperCase() == 'UP';
  bool get diskSpaceUp => diskSpace.toUpperCase() == 'UP';

  factory PlatformHealthDto.fromJson(Map<String, dynamic> json) {
    return PlatformHealthDto(
      status: json['status'] as String? ?? 'UNKNOWN',
      database: json['database'] as String? ?? 'UNKNOWN',
      redis: json['redis'] as String? ?? 'UNKNOWN',
      diskSpace: json['diskSpace'] as String? ?? 'UNKNOWN',
    );
  }
}
