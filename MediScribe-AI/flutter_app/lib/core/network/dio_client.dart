import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import 'auth_interceptor.dart';
import '../../services/auth_provider.dart';

/// Centralized Dio client with auth interceptor, token injection, and error handling.
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      sendTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.acceptHeader: 'application/json',
      },
    ),
  );

  final authService = ref.watch(authServiceProvider);
  dio.interceptors.add(AuthInterceptor(authService, dio));
  dio.interceptors.add(_ErrorInterceptor());
  dio.interceptors.add(_LoggingInterceptor());

  return dio;
});

// ==========================================
// Error Transformation Interceptor
// ==========================================
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Transform Dio errors to user-friendly messages
    final transformed = _transformError(err);
    handler.next(transformed);
  }

  DioException _transformError(DioException err) {
    String message;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timed out. Please check your network.';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection. Please try again.';
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          message = 'Session expired. Please log in again.';
        } else if (statusCode == 403) {
          message = 'Access denied.';
        } else if (statusCode == 404) {
          message = 'Resource not found.';
        } else if (statusCode != null && statusCode >= 500) {
          message = 'Server error. Please try again later.';
        } else {
          message = err.response?.data?['detail']?.toString() ?? 'An error occurred.';
        }
        break;
      default:
        message = 'An unexpected error occurred.';
    }
    return err.copyWith(
      message: message,
    );
  }
}

// ==========================================
// Logging Interceptor (debug only)
// ==========================================
class _LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API] ${options.method} ${options.path}');
      return true;
    }());
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    assert(() {
      // ignore: avoid_print
      print('[API ERROR] ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
      return true;
    }());
    handler.next(err);
  }
}
