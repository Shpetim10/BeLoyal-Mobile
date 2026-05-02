import 'package:flutter/material.dart';

// ── Status Enum ──────────────────────────────────────────────────────────────

/// Maps to the backend `status` field on a CatalogCategory.
/// Backend emits only "ACTIVE" or "INACTIVE".
/// Unknown/future values fall back to [inactive] safely.
enum CategoryStatus {
  active,
  inactive;

  static CategoryStatus fromBackend(String? raw) {
    return switch (raw?.toUpperCase()) {
      'ACTIVE' => CategoryStatus.active,
      _ => CategoryStatus.inactive,
    };
  }

  String get displayName => switch (this) {
    CategoryStatus.active => 'Active',
    CategoryStatus.inactive => 'Inactive',
  };

  Color get color => switch (this) {
    CategoryStatus.active => const Color(0xFF22C55E),
    CategoryStatus.inactive => const Color(0xFF94A3B8),
  };

  Color get backgroundColor => switch (this) {
    CategoryStatus.active => const Color(0xFF22C55E).withValues(alpha: 0.12),
    CategoryStatus.inactive => const Color(0xFF94A3B8).withValues(alpha: 0.12),
  };

  IconData get icon => switch (this) {
    CategoryStatus.active => Icons.check_circle_rounded,
    CategoryStatus.inactive => Icons.pause_circle_rounded,
  };
}

// ── Filter Enum (UI-only) ────────────────────────────────────────────────────

enum CategoryStatusFilter {
  all,
  active,
  inactive;

  String get label => switch (this) {
    CategoryStatusFilter.all => 'All',
    CategoryStatusFilter.active => 'Active',
    CategoryStatusFilter.inactive => 'Inactive',
  };
}

// ── Model ────────────────────────────────────────────────────────────────────

/// Represents a catalog category returned by the BesaHub backend.
///
/// Backend route: /api/besahub/business/{businessId}/catalog-category
class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.name,
    this.description,
    required this.orderIndex,
    required this.status,
    this.createdAt,
  });

  final int id;
  final String name;
  final String? description;
  final int orderIndex;
  final CategoryStatus status;

  /// Nullable — only returned from the GET single / GET all endpoints,
  /// not from the create response body (may be null after POST).
  final DateTime? createdAt;

  bool get isActive => status == CategoryStatus.active;

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    String? parseString(dynamic v) {
      if (v == null) return null;
      if (v is List && v.isNotEmpty) return v.first.toString();
      if (v is List && v.isEmpty) return null;
      return v.toString();
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is String) return DateTime.tryParse(v);
      if (v is List && v.isNotEmpty) {
        int year = (v[0] as num).toInt();
        int month = v.length > 1 ? (v[1] as num).toInt() : 1;
        int day = v.length > 2 ? (v[2] as num).toInt() : 1;
        int hour = v.length > 3 ? (v[3] as num).toInt() : 0;
        int minute = v.length > 4 ? (v[4] as num).toInt() : 0;
        int second = v.length > 5 ? (v[5] as num).toInt() : 0;
        return DateTime(year, month, day, hour, minute, second);
      }
      return null;
    }

    return CatalogCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: parseString(json['name']) ?? '',
      description: parseString(json['description']),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      status: CategoryStatus.fromBackend(parseString(json['status'])),
      // Backend emits LocalDateTime: "2026-03-29T10:30:00" or a list of ints
      createdAt: parseDate(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (description != null) 'description': description,
    'orderIndex': orderIndex,
    'status': status.name.toUpperCase(),
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
  };

  CatalogCategory copyWith({
    int? id,
    String? name,
    String? description,
    bool clearDescription = false,
    int? orderIndex,
    CategoryStatus? status,
    DateTime? createdAt,
  }) {
    return CatalogCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: clearDescription ? null : (description ?? this.description),
      orderIndex: orderIndex ?? this.orderIndex,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'CatalogCategory(id: $id, name: $name, status: ${status.name})';
}
