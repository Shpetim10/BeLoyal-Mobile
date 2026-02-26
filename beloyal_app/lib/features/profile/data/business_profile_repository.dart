import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../media/data/media_repository.dart';
import '../../auth/domain/repositories/auth_repository.dart';
import '../domain/business_profile.dart';

class BusinessProfileRepository {
  BusinessProfileRepository(this._dio);
  final Dio _dio;

  // ── Restaurant Admin ──

  /// GET /business/{businessId} — fetch current admin's business profile.
  Future<AuthResult<BusinessProfile>> fetchMyBusiness(int businessId) async {
    try {
      final response = await _dio.get('/business/$businessId');
      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(BusinessProfile.fromJson(data));
    } on DioException catch (e) {
      return AuthError(_mapError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  /// PATCH /business/{businessId} — update editable business fields for RESTAURANT_ADMIN.
  /// Does NOT allow updating: vatId, status.
  Future<AuthResult<BusinessProfile>> updateMyBusiness({
    required int businessId,
    String? businessName,
    String? businessType,
    String? publicDescription,
    String? address,
    String? city,
    String? country,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
    String? logoPath,
    String? logoKey,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (businessName != null) body['businessName'] = businessName.trim();
      if (businessType != null) body['businessType'] = businessType;
      if (publicDescription != null)
        body['businessDescription'] = publicDescription.trim();
      if (address != null) body['address'] = address.trim();
      if (city != null) body['city'] = city.trim();
      if (country != null) body['country'] = country.trim();
      if (websiteUrl != null) body['websiteUrl'] = websiteUrl.trim();
      if (contactEmail != null) body['businessEmail'] = contactEmail.trim();
      if (contactPhone != null)
        body['businessPhoneNumber'] = contactPhone.trim();
      if (logoPath != null) body['logoPath'] = logoPath;
      if (logoKey != null) body['logoKey'] = logoKey;

      await _dio.patch('/business/$businessId', data: body);
      return fetchMyBusiness(businessId);
    } on DioException catch (e) {
      return AuthError(_mapError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ── Platform Admin / Super Admin ──

  /// GET /admin/business/{businessId} — fetch any business by ID.
  Future<AuthResult<BusinessProfile>> fetchBusiness(int businessId) async {
    try {
      final response = await _dio.get('/admin/business/$businessId');
      final data = response.data as Map<String, dynamic>;
      return AuthSuccess(BusinessProfile.fromJson(data));
    } on DioException catch (e) {
      return AuthError(_mapError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  /// PATCH /admin/business/{businessId} — admin override update (all fields).
  Future<AuthResult<BusinessProfile>> adminUpdateBusiness({
    required int businessId,
    String? businessName,
    String? businessType,
    String? publicDescription,
    String? address,
    String? city,
    String? country,
    String? websiteUrl,
    String? contactEmail,
    String? contactPhone,
    String? vatId,
    String? status,
    String? logoPath,
    String? logoKey,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (businessName != null) body['businessName'] = businessName.trim();
      if (businessType != null) body['businessType'] = businessType;
      if (publicDescription != null)
        body['businessDescription'] = publicDescription.trim();
      if (address != null) body['address'] = address.trim();
      if (city != null) body['city'] = city.trim();
      if (country != null) body['country'] = country.trim();
      if (websiteUrl != null) body['websiteUrl'] = websiteUrl.trim();
      if (contactEmail != null) body['businessEmail'] = contactEmail.trim();
      if (contactPhone != null)
        body['businessPhoneNumber'] = contactPhone.trim();
      if (vatId != null) body['vatId'] = vatId.trim();
      if (status != null) body['businessStatus'] = status;
      if (logoPath != null) body['logoPath'] = logoPath;
      if (logoKey != null) body['logoKey'] = logoKey;

      await _dio.patch('/admin/business/$businessId', data: body);
      return fetchBusiness(businessId);
    } on DioException catch (e) {
      return AuthError(_mapError(e));
    } catch (e) {
      return AuthError(AuthFailure(e.toString()));
    }
  }

  // ── Logo upload helper ──

  /// Uploads logo via MediaRepository and returns url+key map.
  Future<Map<String, String>> uploadLogo({
    required XFile file,
    required int businessId,
    required Ref ref,
  }) async {
    final mediaRepo = ref.read(mediaRepositoryProvider);
    return mediaRepo.uploadImage(
      file: file,
      category: 'BUSINESS_LOGO',
      ownerId: businessId,
    );
  }

  // ── Error mapping ──

  AuthFailure _mapError(DioException e) {
    if (e.response?.data is Map<String, dynamic>) {
      final data = e.response!.data as Map<String, dynamic>;
      final msg = data['message'] as String? ?? 'Something went wrong';
      final fieldErrors = <String, String>{};
      if (data.containsKey('fieldErrors') && data['fieldErrors'] is Map) {
        (data['fieldErrors'] as Map).forEach((k, v) {
          fieldErrors[k.toString()] = v.toString();
        });
      }
      return AuthFailure(msg, fieldErrors: fieldErrors);
    }
    return switch (e.type) {
      DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout =>
        const AuthFailure('Connection timed out. Check your network.'),
      DioExceptionType.connectionError => const AuthFailure(
        'Cannot reach server. Is the backend running?',
      ),
      _ => AuthFailure(e.message ?? 'Network error'),
    };
  }
}

final businessProfileRepositoryProvider = Provider<BusinessProfileRepository>((
  ref,
) {
  return BusinessProfileRepository(ref.watch(dioProvider));
});
