import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:mediscribe_app/core/network/auth_interceptor.dart';
import 'package:mediscribe_app/services/auth_service.dart';

class MockAuthService extends Mock implements AuthService {}
class MockDio extends Mock implements Dio {}
class MockErrorInterceptorHandler extends Mock implements ErrorInterceptorHandler {}

void main() {
  late AuthInterceptor interceptor;
  late MockAuthService mockAuthService;
  late MockDio mockDio;
  late MockErrorInterceptorHandler mockHandler;

  setUp(() {
    mockAuthService = MockAuthService();
    mockDio = MockDio();
    mockHandler = MockErrorInterceptorHandler();
    interceptor = AuthInterceptor(mockAuthService, mockDio);
    
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('AuthInterceptor', () {
    test('onError intercepts 401, refreshes token, and retries request', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api/data');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      when(() => mockAuthService.getRefreshToken()).thenAnswer((_) async => 'valid_refresh_token');
      when(() => mockAuthService.refreshTokens('valid_refresh_token')).thenAnswer((_) async => {
        'access_token': 'new_access_token',
        'refresh_token': 'new_refresh_token',
      });
      
      final retryResponse = Response(
        requestOptions: requestOptions,
        statusCode: 200,
        data: 'success',
      );
      
      when(() => mockDio.fetch(any())).thenAnswer((_) async => retryResponse);

      // Act
      interceptor.onError(err, mockHandler);

      // We need a small delay because onError doesn't return a Future, 
      // but it performs async operations internally.
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockAuthService.getRefreshToken()).called(1);
      verify(() => mockAuthService.refreshTokens('valid_refresh_token')).called(1);
      
      // Verify that it fetched the original request again with the new token
      final captured = verify(() => mockDio.fetch(captureAny())).captured;
      final retriedOptions = captured.first as RequestOptions;
      expect(retriedOptions.headers['Authorization'], 'Bearer new_access_token');
      
      // Verify that handler.resolve was called with the retry response
      verify(() => mockHandler.resolve(retryResponse)).called(1);
    });

    test('onError forces logout when refresh token is missing', () async {
      // Arrange
      final requestOptions = RequestOptions(path: '/api/data');
      final err = DioException(
        requestOptions: requestOptions,
        response: Response(
          requestOptions: requestOptions,
          statusCode: 401,
        ),
      );

      when(() => mockAuthService.getRefreshToken()).thenAnswer((_) async => null);
      when(() => mockAuthService.logout()).thenAnswer((_) async => {});

      // Act
      interceptor.onError(err, mockHandler);
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      verify(() => mockAuthService.getRefreshToken()).called(1);
      verify(() => mockAuthService.logout()).called(1);
      verify(() => mockHandler.next(err)).called(1);
    });
  });
}
