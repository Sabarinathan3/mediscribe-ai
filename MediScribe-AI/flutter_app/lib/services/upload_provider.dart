import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_provider.dart';
import 'auth_service.dart';
import '../core/constants/app_constants.dart';

// ==========================================
// Upload States
// ==========================================
abstract class UploadState {
  const UploadState();
}

class UploadIdle extends UploadState {
  const UploadIdle();
}

class ImageSelected extends UploadState {
  final XFile file;
  const ImageSelected(this.file);
}

class UploadProgress extends UploadState {
  final double percentage; // from 0.0 to 1.0
  const UploadProgress(this.percentage);
}

class ProcessingOCR extends UploadState {
  const ProcessingOCR();
}

class OCRSuccess extends UploadState {
  final Map<String, dynamic> responseData;
  const OCRSuccess(this.responseData);
}

class UploadError extends UploadState {
  final String errorMessage;
  const UploadError(this.errorMessage);
}

// ==========================================
// Providers
// ==========================================
final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return UploadNotifier(authService);
});

// ==========================================
// Notifier implementation
// ==========================================
class UploadNotifier extends StateNotifier<UploadState> {
  final AuthService _authService;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
  ));

  UploadNotifier(this._authService) : super(const UploadIdle());

  void selectImage(XFile file) {
    state = ImageSelected(file);
  }

  void clearSelection() {
    state = const UploadIdle();
  }

  Future<void> uploadAndProcessPrescription(XFile file, {String targetLang = 'en'}) async {
    try {
      state = const UploadProgress(0.0);

      // Read token if backend requires auth for AI routes (it doesn't require on /ai/process-prescription, but good practice)
      final token = await _authService.getAccessToken();
      final headers = <String, String>{};
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }

      // Prepare Multipart file upload
      final File imageFile = File(file.path);
      final String fileName = file.name;

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      // Execute POST request to FastAPI AI Pipeline
      final response = await _dio.post(
        '/ai/process-prescription',
        data: formData,
        queryParameters: {'target_lang': targetLang},
        options: Options(headers: headers),
        onSendProgress: (sent, total) {
          if (total > 0) {
            final double progress = sent / total;
            // Cap progress at 0.99 until OCR finishes processing
            state = UploadProgress(progress * 0.95);
          }
        },
      );

      state = const ProcessingOCR();

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        state = OCRSuccess(data);
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final String detail = e.response?.data?['detail'] ?? e.message ?? 'Network connection failed.';
      state = UploadError(detail);
    } catch (e) {
      state = UploadError(e.toString().replaceAll('Exception: ', ''));
    }
  }
}
