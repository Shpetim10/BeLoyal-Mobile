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

  /// Resolve a guest by their loyalty QR code payload.
  ///
  /// **Request:**
  /// ```
  /// GET /business/{businessId}/customers/lookup?loyaltyId=BESA-CUST-00042
  /// ```
  ///
  /// **Expected response (200):**
  /// ```json
  /// {
  ///   "customerId": 42,
  ///   "loyaltyId": "BESA-CUST-00042",
  ///   "firstName": "Arta",
  ///   "lastName": "Hoxha",
  ///   "email": "arta@example.com",
  ///   "currentPoints": 1250
  /// }
  /// ```
  ///
  /// **Error responses:**
  /// - 404: Customer not found for this loyalty ID
  /// - 400: Invalid loyalty ID format
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
  ///
  /// **Request:**
  /// ```
  /// GET /business/{businessId}/customers/lookup?email=arta@example.com
  /// ```
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
  ///
  /// **Request:**
  /// ```
  /// GET /business/{businessId}/customers/lookup?manualCode=BESA-CUST-00042
  /// ```
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

  /// Preview the points that would be earned for a given bill amount.
  ///
  /// **Request:**
  /// ```
  /// GET /business/{businessId}/transactions/earn-points/preview
  ///   ?billAmount=5000.50
  ///   &guests=42
  ///   &guests=99
  /// ```
  ///
  /// **Expected response (200):**
  /// ```json
  /// {
  ///   "totalPoints": 50,
  ///   "remainingPoints": 50,
  ///   "primaryCustomerId": 42,
  ///   "pointsPer": 1,
  ///   "amountPer": 100.0,
  ///   "maxPointsPerTransaction": 500,
  ///   "guestPointsResults": [
  ///     { "customerId": 42, "earnedPoints": 25, "currentBalance": 1250 },
  ///     { "customerId": 99, "earnedPoints": 25, "currentBalance": 800 }
  ///   ]
  /// }
  /// Preview the points that would be earned for a given bill amount.
  ///
  /// **Request:**
  /// ```
  /// POST /business/{businessId}/transactions/earn-points/preview
  /// {
  ///   "billAmount": 5000.5,
  ///   "guests": [
  ///     { "customerId": 42 },
  ///     { "customerId": 99 }
  ///   ]
  /// }
  /// ```
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

  /// Submit the final earn-points transaction.
  ///
  /// **Request:**
  /// ```
  /// POST /business/{businessId}/transactions/earn
  /// Content-Type: application/json
  ///
  /// {
  ///   "billAmountAll": 5000,
  ///   "guestAllocations": [
  ///     { "customerId": 42, "shareAmount": 2500 },
  ///     { "customerId": 99, "shareAmount": 2500 }
  ///   ],
  ///   "invoiceNumber": "INV-2026-0314",
  ///   "note": "Table 7 split bill"
  /// }
  /// ```
  ///
  /// **Expected response (201):**
  /// ```json
  /// {
  ///   "transactionId": 1001,
  ///   "status": "COMPLETED",
  ///   "totalPointsAwarded": 50,
  ///   "createdAt": "2026-03-14T17:30:00Z"
  /// }
  /// ```
  Future<PointsPreview> submitEarnTransaction({
    required int businessId,
    required EarnTransactionRequest request,
  }) async {
    final response = await _dio.post(
      '/business/$businessId/transactions/earn',
      data: request.toJson(),
    );
    return PointsPreview.fromJson(response.data as Map<String, dynamic>);
  }
}

final earnPointsRepositoryProvider = Provider<EarnPointsRepository>((ref) {
  return EarnPointsRepository(ref.watch(dioProvider));
});
