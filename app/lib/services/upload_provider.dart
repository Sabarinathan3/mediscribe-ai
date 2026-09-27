import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/dio_client.dart';

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
  final dio = ref.watch(dioClientProvider);
  return UploadNotifier(dio);
});

// ==========================================
// Notifier implementation
// ==========================================
class UploadNotifier extends StateNotifier<UploadState> {
  final Dio _dio;
  static const int _maxRetries = 2;

  UploadNotifier(this._dio) : super(const UploadIdle());

  void selectImage(XFile file) {
    state = ImageSelected(file);
  }

  void clearSelection() {
    state = const UploadIdle();
  }

  Future<void> uploadAndProcessPrescription(XFile file, {String targetLang = 'en'}) async {
    try {
      state = const UploadProgress(0.0);

      final File imageFile = File(file.path);
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: file.name,
        ),
      });

      final response = await _postWithRetry(
        '/ai/process-prescription',
        formData: formData,
        queryParameters: {'target_lang': targetLang},
        onSendProgress: (sent, total) {
          if (total > 0) {
            state = UploadProgress((sent / total) * 0.95);
          }
        },
      );

      state = const ProcessingOCR();

      if (response.statusCode == 200) {
        state = OCRSuccess(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      state = UploadError(_friendlyError(e));
    } catch (e) {
      state = UploadError(_stripExceptionPrefix(e.toString()));
    }
  }

  Future<Response<dynamic>> _postWithRetry(
    String path, {
    required FormData formData,
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onSendProgress,
  }) async {
    DioException? lastError;

    for (var attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        return await _dio.post(
          path,
          data: formData,
          queryParameters: queryParameters,
          onSendProgress: onSendProgress,
        );
      } on DioException catch (e) {
        lastError = e;
        final isRetryable = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;

        if (!isRetryable || attempt == _maxRetries) {
          rethrow;
        }
      }
    }

    throw lastError!;
  }

  String _friendlyError(DioException e) {
    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }
    return 'Network connection failed. Please try again.';
  }

  String _stripExceptionPrefix(String message) {
    return message.replaceAll(RegExp(r'^(\w+Exception:\s*)+'), '').trim();
  }
}
