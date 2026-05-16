import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'business_status.dart';

/// Helper utilities for resolving and displaying business status
extension BusinessStatusResolver on String? {
  /// Safely convert a backend status string to BusinessStatus enum
  BusinessStatus toBusinessStatus() {
    if (this == null) return BusinessStatus.active;
    return BusinessStatus.fromBackend(this) ?? BusinessStatus.active;
  }

  /// Get the appropriate color for this status
  Color get statusColor {
    final status = toBusinessStatus();
    return status.color;
  }

  /// Get the appropriate icon for this status
  IconData get statusIcon {
    final status = toBusinessStatus();
    return status.icon;
  }

  /// Get the display name for this status
  String get statusDisplayName {
    final status = toBusinessStatus();
    return status.displayName;
  }

  /// Check if this status allows normal operations
  bool get isOperational {
    final status = toBusinessStatus();
    return status.isOperational;
  }

  /// Check if this is a terminal rejection state
  bool get isRejected {
    final status = toBusinessStatus();
    return status.isRejected;
  }

  /// Check if this status requires admin attention
  bool get requiresAdminAction {
    final status = toBusinessStatus();
    return status.requiresAdminAction;
  }
}

/// Helper to resolve status with fallback to display names
class BusinessStatusDisplay {
  static String getDisplayName(String? status, String? displayNameFromBackend) {
    if (displayNameFromBackend != null && displayNameFromBackend.isNotEmpty) {
      return displayNameFromBackend;
    }
    return status?.toBusinessStatus().displayName ??
        BusinessStatus.active.displayName;
  }

  static String getDescription(String? status, String? descriptionFromBackend) {
    if (descriptionFromBackend != null && descriptionFromBackend.isNotEmpty) {
      return descriptionFromBackend;
    }
    return status?.toBusinessStatus().description ??
        BusinessStatus.active.description;
  }

  static Color getColor(String? status) {
    return status?.statusColor ?? AppColors.secondary;
  }

  static IconData getIcon(String? status) {
    return status?.statusIcon ?? Icons.check_circle_rounded;
  }
}
