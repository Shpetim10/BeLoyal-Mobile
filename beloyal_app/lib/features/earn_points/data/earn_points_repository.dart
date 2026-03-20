import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import 'models/resolved_guest.dart';
import 'models/points_preview.dart';
import 'models/earn_transaction_request.dart';

/// Repository for the Earn Points workflow.
///
/// All endpoints are scoped to a business via [businessId].
class EarnPointsRepository {
  EarnPointsRepository(this._dio);
  final Dio _dio;

  // ── Guest Lookup ──────────────────────────────────────────────────────────

  Future<ResolvedGuest> lookupByQrToken({
    required int businessId,
    required String qrToken,
  }) async {
    final response = await _dio.get(
      '/business/$businessId/customers/lookup',
      queryParameters: {'qrToken': qrToken},
    );
    return ResolvedGuest.fromJson(response.data as Map<String, dynamic>);
  }

  /// Search customer by email.
  Future<ResolvedGuest> lookupByEmail({
    required int businessId,
    required String email,
  }) async {
    final response = await _dio.get(
      '/business/$businessId/customers/lookup',
      queryParameters: {'email': email},
    );
    return ResolvedGuest.fromJson(response.data as Map<String, dynamic>);
  }

  /// Search customer by manual code (loyalty ID).
  Future<ResolvedGuest> lookupByManualCode({
    required int businessId,
    required String manualCode,
  }) async {
    final response = await _dio.get(
      '/business/$businessId/customers/lookup',
      queryParameters: {'manualCode': manualCode},
    );
    return ResolvedGuest.fromJson(response.data as Map<String, dynamic>);
  }

  // ── Points Preview ────────────────────────────────────────────────────────
  Future<PointsPreview> previewPoints({
    required int businessId,
    required double billAmount,
    required List<GuestAllocation> guests,
  }) async {
    final response = await _dio.post(
      '/business/$businessId/transactions/earn-points/preview',
      data: {
        'billAmount': billAmount,
        'guests': [
          for (final g in guests) {'customerId': g.customerId},
        ],
      },
    );
    return PointsPreview.fromJson(response.data as Map<String, dynamic>);
  }


  // ── Transaction Submission ────────────────────────────────────────────────
  Future<PointsPreview> submitEarnTransaction({
    required int businessId,
    required EarnTransactionRequest request,
    required String idempotencyKey,
  }) async {
    final response = await _dio.post(
      '/business/$businessId/transactions/earn',
      data: request.toJson(),
      options: Options(
        headers: {
          'Idempotency-Key': idempotencyKey,
        },
      ),
    );
    return PointsPreview.fromJson(response.data as Map<String, dynamic>);
  }
}

final earnPointsRepositoryProvider = Provider<EarnPointsRepository>((ref) {
  return EarnPointsRepository(ref.watch(dioProvider));
});
