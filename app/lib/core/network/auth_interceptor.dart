import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';

class AuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  AuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Inject token into header if it exists
    final token = await _authService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token might be expired. Let's try to refresh it.
      debugPrint('AuthInterceptor: 401 Unauthorized caught. Attempting token refresh...');
      final refreshToken = await _authService.getRefreshToken();
      
      if (refreshToken != null) {
        try {
          final data = await _authService.refreshTokens(refreshToken);
          final newAccess = data['access_token'] as String;

          // Retry original request with new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newAccess';

          final response = await _dio.fetch(requestOptions);
          return handler.resolve(response);
        } catch (refreshErr) {
          debugPrint('AuthInterceptor: Token refresh failed: $refreshErr');
          // Refresh failed, logout
          await _authService.logout();
        }
      } else {
        // No refresh token, force logout
        await _authService.logout();
      }
    }
    
    return handler.next(err);
  }
}
