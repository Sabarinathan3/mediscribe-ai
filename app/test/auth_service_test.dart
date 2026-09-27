import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mediscribe_app/services/auth_service.dart';
import 'package:mediscribe_app/models/user_model.dart';
import 'package:mediscribe_app/core/constants/app_constants.dart';

class MockDio extends Mock implements Dio {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockFlutterSecureStorage();
    authService = AuthService(dio: mockDio, secureStorage: mockSecureStorage);

    // Register fallback values if needed by mocktail
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('AuthService', () {
    test('login() with valid credentials saves tokens and returns data', () async {
      // Arrange
      final responseData = {
        'access_token': 'fake_access_token',
        'refresh_token': 'fake_refresh_token',
        'token_type': 'bearer'
      };
      
      when(() => mockDio.post(any(), data: any(named: 'data')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auth/login'),
                statusCode: 200,
                data: responseData,
              ));

      when(() => mockSecureStorage.write(key: AppConstants.keyAccessToken, value: 'fake_access_token'))
          .thenAnswer((_) async => {});
      when(() => mockSecureStorage.write(key: AppConstants.keyRefreshToken, value: 'fake_refresh_token'))
          .thenAnswer((_) async => {});

      // Act
      final result = await authService.login('+1234567890', 'password123');

      // Assert
      expect(result['access_token'], 'fake_access_token');
      verify(() => mockSecureStorage.write(key: AppConstants.keyAccessToken, value: 'fake_access_token')).called(1);
      verify(() => mockSecureStorage.write(key: AppConstants.keyRefreshToken, value: 'fake_refresh_token')).called(1);
    });

    test('logout() deletes tokens from secure storage', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: AppConstants.keyRefreshToken))
          .thenAnswer((_) async => null);
      when(() => mockSecureStorage.delete(key: AppConstants.keyAccessToken))
          .thenAnswer((_) async => {});
      when(() => mockSecureStorage.delete(key: AppConstants.keyRefreshToken))
          .thenAnswer((_) async => {});

      // Act
      await authService.logout();

      // Assert
      verify(() => mockSecureStorage.delete(key: AppConstants.keyAccessToken)).called(1);
      verify(() => mockSecureStorage.delete(key: AppConstants.keyRefreshToken)).called(1);
    });

    test('getMe() parses UserModel correctly from response', () async {
      // Arrange
      final userData = {
        'id': 'user_123',
        'full_name': 'John Doe',
        'phone': '+1234567890',
        'role': 'patient',
        'locale': 'en',
        'is_active': true,
      };

      when(() => mockSecureStorage.read(key: AppConstants.keyAccessToken))
          .thenAnswer((_) async => 'fake_access_token');

      when(() => mockDio.get(any(), options: any(named: 'options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/auth/me'),
                statusCode: 200,
                data: userData,
              ));

      // Act
      final user = await authService.getMe();

      // Assert
      expect(user, isA<UserModel>());
      expect(user.id, 'user_123');
      expect(user.fullName, 'John Doe');
      expect(user.role, 'patient');
    });
  });
}
