import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';

class MediaRepository {
  MediaRepository(this._dio);
  final Dio _dio;

  /// Uploads an image to the backend and returns the URL and key.
  /// POST /media/images (multipart/form-data)
  Future<Map<String, String>> uploadImage({
    required XFile file,
    required String category,
    required int ownerId,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'category': category,
        'ownerId': ownerId.toString(),
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dio.post(
        '/media/images',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          extra: {
            'isFormData': true,
            'formDataFields': formData.fields,
            'formDataFiles': [
              {'key': 'file', 'path': file.path, 'filename': fileName},
            ],
          },
        ),
      );

      final data = response.data as Map<String, dynamic>;

      return {'url': data['url'] as String, 'key': data['key'] as String};
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = e.response?.data['message'] ?? 'Upload failed';
        throw Exception(msg);
      }
      throw Exception(e.message ?? 'Network error during upload');
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(ref.watch(dioProvider));
});
