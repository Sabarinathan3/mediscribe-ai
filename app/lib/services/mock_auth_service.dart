import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// A temporary Mock Authentication Service.
/// TODO: Replace with real authentication later
class MockAuthService extends AuthService {
  final FlutterSecureStorage _mockSecureStorage;
  UserModel? _currentUser;
  bool _isLoggedIn = false;

  MockAuthService({super.dio, super.secureStorage})
      : _mockSecureStorage = secureStorage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );

  @override
  Future<Map<String, dynamic>> login([
    String phoneOrEmail = 'mockuser@example.com',
    String password = 'password123',
  ]) async {
    // TODO: Replace with real authentication later
    if (phoneOrEmail.trim().isEmpty || password.isEmpty) {
      throw Exception('Email/phone and password cannot be empty');
    }

    final mockUser = UserModel(
      id: 'mock_id_123',
      userId: 'mock_user_123',
      fullName: 'Mock User',
      phone: phoneOrEmail.contains('@') ? null : phoneOrEmail,
      email: phoneOrEmail.contains('@') ? phoneOrEmail : 'mockuser@example.com',
      locale: 'en',
      role: 'patient',
      isActive: true,
    );

    _currentUser = mockUser;
    _isLoggedIn = true;

    await saveTokens('mock_access_token', 'mock_refresh_token');
    await _saveMockUser(mockUser);

    return {
      'access_token': 'mock_access_token',
      'refresh_token': 'mock_refresh_token',
      'user': mockUser.toJson(),
    };
  }

  @override
  Future<Map<String, dynamic>> register([
    String fullName = 'Mock User',
    String phoneOrEmail = 'mockuser@example.com',
    String password = 'password123',
    String role = 'patient',
  ]) async {
    // TODO: Replace with real authentication later
    if (fullName.trim().isEmpty || phoneOrEmail.trim().isEmpty || password.isEmpty) {
      throw Exception('All fields are required');
    }

    final mockUser = UserModel(
      id: 'mock_id_123',
      userId: 'mock_user_123',
      fullName: fullName,
      phone: phoneOrEmail.contains('@') ? null : phoneOrEmail,
      email: phoneOrEmail.contains('@') ? phoneOrEmail : 'mockuser@example.com',
      locale: 'en',
      role: role,
      isActive: true,
    );

    _currentUser = mockUser;
    _isLoggedIn = true;

    await saveTokens('mock_access_token', 'mock_refresh_token');
    await _saveMockUser(mockUser);

    return {
      'access_token': 'mock_access_token',
      'refresh_token': 'mock_refresh_token',
      'user': mockUser.toJson(),
    };
  }

  @override
  Future<UserModel> getMe() async {
    // TODO: Replace with real authentication later
    if (_currentUser != null) {
      return _currentUser!;
    }
    final persistedUser = await _loadMockUser();
    if (persistedUser != null) {
      _currentUser = persistedUser;
      _isLoggedIn = true;
      return persistedUser;
    }
    throw Exception('No authenticated user session found');
  }

  @override
  Future<void> logout() async {
    // TODO: Replace with real authentication later
    _currentUser = null;
    _isLoggedIn = false;
    await clearTokensLocally();
    await _clearMockUser();
  }

  @override
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    // TODO: Replace with real authentication later
    return {
      'access_token': 'mock_access_token',
      'refresh_token': 'mock_refresh_token',
    };
  }

  // ============================================================
  // Additional requested methods
  // ============================================================

  /// Returns true if a mock user is logged in (i.e. has a valid access token).
  /// TODO: Replace with real authentication later
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    if (token != null) {
      _isLoggedIn = true;
      return true;
    }
    return _isLoggedIn;
  }

  /// Returns the currently authenticated mock user, or null if not logged in.
  /// TODO: Replace with real authentication later
  Future<UserModel?> getCurrentUser() async {
    try {
      return await getMe();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // Internal storage helpers
  // ============================================================

  Future<void> _saveMockUser(UserModel user) async {
    try {
      final jsonStr = jsonEncode(user.toJson());
      await _mockSecureStorage.write(key: 'mock_user_data', value: jsonStr);
    } catch (e) {
      debugPrint('[MockAuthService] Error saving mock user: $e');
    }
  }

  Future<UserModel?> _loadMockUser() async {
    try {
      final jsonStr = await _mockSecureStorage.read(key: 'mock_user_data');
      if (jsonStr != null) {
        return UserModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('[MockAuthService] Error loading mock user: $e');
    }
    return null;
  }

  Future<void> _clearMockUser() async {
    try {
      await _mockSecureStorage.delete(key: 'mock_user_data');
    } catch (e) {
      debugPrint('[MockAuthService] Error clearing mock user: $e');
    }
  }
}
