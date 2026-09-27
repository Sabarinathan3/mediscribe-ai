import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ) {
    if (dio != null) {
      _dio = dio;
    } else {
      _dio = Dio(BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      ));

      // FIX Issue #2: Auto-refresh interceptor — silently retries 401s with a new
      // access token instead of kicking the user out on token expiry.
      _dio.interceptors.add(
        InterceptorsWrapper(
          onError: (DioException error, ErrorInterceptorHandler handler) async {
            if (error.response?.statusCode == 401) {
              final refresh = await getRefreshToken();
              if (refresh != null) {
                try {
                  await _doRefreshTokens(refresh);
                  final newToken = await getAccessToken();
                  if (newToken != null) {
                    // Clone & retry the original request with the fresh token
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newToken';
                    final cloneReq = await _dio.fetch(opts);
                    return handler.resolve(cloneReq);
                  }
                } catch (_) {
                  // Refresh also failed — log out cleanly
                  await logout();
                }
              }
            }
            return handler.next(error);
          },
        ),
      );
    }
  }

  // ============================================================
  // Auth API calls
  // ============================================================

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      // Backend expects form-data for OAuth2PasswordRequestForm
      final formData = FormData.fromMap({
        'username': phone,
        'password': password,
      });

      final response = await _dio.post('/auth/login', data: formData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await saveTokens(
          data['access_token'] as String,
          data['refresh_token'] as String,
        );
        return data;
      } else {
        throw Exception('Failed to login: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String phone,
    String password,
    String role,
  ) async {
    try {
      // FIX Issue #7 (Flutter side): enforce +countrycode format before hitting API
      final trimmedPhone = phone.trim();
      if (!RegExp(r'^\+[1-9]\d{6,14}$').hasMatch(trimmedPhone)) {
        throw Exception(
          'Phone must start with + and include country code (e.g. +911234567890)',
        );
      }

      // Send a flat JSON body to match UserRegisterRequest Pydantic schema on backend.
      final response = await _dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'phone': trimmedPhone,
          'password': password,
          'locale': 'en',
          'role': role,
          'is_active': true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        await saveTokens(
          data['access_token'] as String,
          data['refresh_token'] as String,
        );
        return data;
      } else {
        throw Exception('Failed to register: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['detail'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  Future<UserModel> getMe() async {
    try {
      final token = await getAccessToken();
      if (token == null) throw Exception('No access token found');

      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch user info');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Failed to load user profile');
    }
  }

  // ============================================================
  // Token management
  // ============================================================

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _secureStorage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
  }

  /// Deletes tokens from local storage only — no network call.
  /// Prefer this in error-recovery paths where the network may be unavailable.
  Future<void> clearTokensLocally() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }

  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage
          .read(key: AppConstants.keyAccessToken)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("DEBUG: Secure storage read access token failed: $e");
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage
          .read(key: AppConstants.keyRefreshToken)
          .timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("DEBUG: Secure storage read refresh token failed: $e");
      return null;
    }
  }

  /// FIX Issue #3 (Flutter): refresh token sent in JSON body — NOT query param.
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    return _doRefreshTokens(refreshToken);
  }

  /// Internal helper used by both the public API and the interceptor.
  Future<Map<String, dynamic>> _doRefreshTokens(String refreshToken) async {
    try {
      final response = await _dio.post(
        '/auth/refresh',
        // FIX Issue #3: was queryParameters — now JSON body to avoid log leakage
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        await saveTokens(
          data['access_token'] as String,
          data['refresh_token'] as String,
        );
        return data;
      }
      throw Exception('Failed to refresh token');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['detail'] ?? 'Session expired');
    }
  }

  Future<void> logout() async {
    try {
      final refresh = await getRefreshToken();
      if (refresh != null) {
        // We do not want this API call to trigger the AuthInterceptor's retry loop if it 401s
        await _dio.post(
          '/auth/logout',
          data: {'refresh_token': refresh},
        ).timeout(const Duration(seconds: 5)); // prevent hanging on logout
      }
    } catch (e) {
      // Ignore network errors or 401s on logout, we still want to clear local state
    } finally {
      await clearTokensLocally();
    }
  }
}
