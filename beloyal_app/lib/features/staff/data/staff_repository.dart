import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/models/staff_member.dart';

/// Repository handling all Staff-related API calls.
class StaffRepository {
  StaffRepository(this._dio);
  final Dio _dio;

  // ── Fetch all staff for a business ──
  Future<List<StaffMember>> fetchStaff(int businessId) async {
    try {
      final response = await _dio.get('/business/$businessId/staff');

      final data = response.data;
      if (data is List) {
        return data
            .map((e) => StaffMember.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Update member status (activate / deactivate) ──
  Future<void> updateMemberStatus(
    int businessId,
    int memberId,
    MemberStatus newStatus,
  ) async {
    try {
      await _dio.patch(
        '/business/$businessId/staff/$memberId/status',
        data: {'memberStatus': newStatus.backendValue},
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Invite a new staff member ──
  Future<void> inviteStaff(
    int businessId, {
    required String email,
    DateTime? hireDate,
    String role = 'STAFF',
  }) async {
    try {
      final body = <String, dynamic>{'email': email, 'role': role};
      if (hireDate != null) {
        body['hireDate'] = hireDate.toIso8601String().split('T').first;
      }

      await _dio.post('/business/$businessId/staff/invite', data: body);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ── Error mapper ──
  String _mapError(DioException e) {
    if (e.response?.data is Map) {
      final msg = (e.response!.data as Map)['message'];
      if (msg != null) return msg.toString();
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        'Connection timed out. Please try again.',
      DioExceptionType.connectionError =>
        'Could not reach the server. Check your connection.',
      _ => e.message ?? 'Something went wrong.',
    };
  }
}

/// Riverpod provider for [StaffRepository].
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(dioProvider));
});
