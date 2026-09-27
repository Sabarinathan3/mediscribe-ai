import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../services/auth_service.dart';
import '../constants/app_constants.dart';

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
          // Attempt refresh
          final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
          final refreshResponse = await refreshDio.post(
            '/auth/refresh',
            options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
          );

          if (refreshResponse.statusCode == 200) {
            final newAccess = refreshResponse.data['access_token'];
            final newRefresh = refreshResponse.data['refresh_token'];
            
            // Note: _authService._saveTokens is private, but we can do a workaround
            // Wait, we need a public method to save tokens or just use the secure storage here.
            // But since this is in the same app we'll add a public `saveTokens` method later,
            // or we can use a separate logic. Let's assume we add `saveTokens` to AuthService.
            await _authService.saveTokens(newAccess, newRefresh);
            
            // Retry original request with new token
            final requestOptions = err.requestOptions;
            requestOptions.headers['Authorization'] = 'Bearer $newAccess';
            
            // Retry the request
            final response = await _dio.fetch(requestOptions);
            return handler.resolve(response);
          }
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
