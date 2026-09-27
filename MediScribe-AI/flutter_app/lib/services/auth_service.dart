import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConstants.connectionTimeoutMs),
    receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
  ));

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        
        await saveTokens(accessToken, refreshToken);
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
    String role
  ) async {
    try {
      // Send a flat JSON body to match UserRegisterRequest Pydantic schema on backend.
      // The old nested format {'user_in': {...}, 'password': ...} caused 422 errors.
      final response = await _dio.post(
        '/auth/register',
        data: {
          'full_name': fullName,
          'phone': phone,
          'password': password,
          'locale': 'en',
          'role': role,
          'is_active': true,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final accessToken = data['access_token'] as String;
        final refreshToken = data['refresh_token'] as String;
        
        await saveTokens(accessToken, refreshToken);
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

  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(key: AppConstants.keyAccessToken, value: accessToken);
    await _secureStorage.write(key: AppConstants.keyRefreshToken, value: refreshToken);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: AppConstants.keyAccessToken);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: AppConstants.keyRefreshToken);
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: AppConstants.keyAccessToken);
    await _secureStorage.delete(key: AppConstants.keyRefreshToken);
  }
}
