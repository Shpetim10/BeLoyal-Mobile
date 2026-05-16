import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Business status enum matching backend values
enum BusinessStatus {
  active('ACTIVE'),
  inactive('INACTIVE'),
  pendingApproval('PENDING_APPROVAL'),
  rejected('REJECTED'),
  banned('BANNED');

  const BusinessStatus(this.backendValue);
  final String backendValue;

  /// Parse backend string to enum
  static BusinessStatus? fromBackend(String? value) {
    if (value == null) return null;
    try {
      return BusinessStatus.values.firstWhere(
        (s) => s.backendValue == value.toUpperCase(),
      );
    } catch (_) {
      return null;
    }
  }

  /// User-friendly display name
  String get displayName {
    return switch (this) {
      BusinessStatus.active => 'Active',
      BusinessStatus.inactive => 'Inactive',
      BusinessStatus.pendingApproval => 'Approval is pending',
      BusinessStatus.rejected => 'Rejected',
      BusinessStatus.banned => 'Banned',
    };
  }

  /// Description for each status
  String get description {
    return switch (this) {
      BusinessStatus.active =>
        'Business can be seen and can operate transactions!',
      BusinessStatus.inactive =>
        'Business cannot be seen and cannot operate transactions!',
      BusinessStatus.pendingApproval =>
        'Your application is being verified by the support. This process may take a while!',
      BusinessStatus.rejected =>
        'Your application was rejected. Please contact support if you think there was something wrong.',
      BusinessStatus.banned => 'Your business was banned!',
    };
  }

  /// Status color for UI display
  Color get color {
    return switch (this) {
      BusinessStatus.active => AppColors.secondary,
      BusinessStatus.inactive => AppColors.warning,
      BusinessStatus.pendingApproval => AppColors.warning,
      BusinessStatus.rejected => AppColors.error,
      BusinessStatus.banned => AppColors.error,
    };
  }

  /// Icon for status display
  IconData get icon {
    return switch (this) {
      BusinessStatus.active => Icons.check_circle_rounded,
      BusinessStatus.inactive => Icons.pause_circle_rounded,
      BusinessStatus.pendingApproval => Icons.hourglass_bottom_rounded,
      BusinessStatus.rejected => Icons.cancel_rounded,
      BusinessStatus.banned => Icons.block_rounded,
    };
  }

  /// Whether this status allows normal business operations
  bool get isOperational => this == BusinessStatus.active;

  /// Whether this status is a terminal rejection state
  bool get isRejected =>
      this == BusinessStatus.rejected || this == BusinessStatus.banned;

  /// Whether this status requires admin attention
  bool get requiresAdminAction =>
      this == BusinessStatus.pendingApproval || isRejected;
}
