import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediscribe_app/core/network/dio_client.dart';
import 'package:mediscribe_app/core/constants/app_constants.dart';

void main() {
  group('DioClientProvider', () {
    test('Dio instance has correct base options configured', () {
      final container = ProviderContainer();
      final dio = container.read(dioClientProvider);

      expect(dio.options.baseUrl, AppConstants.apiBaseUrl);
      expect(dio.options.connectTimeout, const Duration(milliseconds: AppConstants.connectionTimeoutMs));
      expect(dio.options.receiveTimeout, const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      expect(dio.options.sendTimeout, const Duration(milliseconds: AppConstants.receiveTimeoutMs));
      expect(dio.options.headers['Content-Type'], 'application/json');
      expect(dio.options.headers['Accept'], 'application/json');
      
      container.dispose();
    });
  });
}
