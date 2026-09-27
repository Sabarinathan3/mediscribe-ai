import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('apiBaseUrl has correct default or environment value', () {
      // By default, if no --dart-define is passed to flutter test, 
      // this should match the defaultValue in String.fromEnvironment.
      // If this test is run with --dart-define=API_BASE_URL=https://prod.api.com,
      // this test will fail if it's strictly checking for the default. 
      // So we just ensure it's not empty and is a valid URL string.
      expect(AppConstants.apiBaseUrl, isNotEmpty);
      expect(AppConstants.apiBaseUrl.startsWith('http'), isTrue);
    });

    test('timeout constants are properly defined', () {
      expect(AppConstants.connectionTimeoutMs, 15000);
      expect(AppConstants.receiveTimeoutMs, 30000);
    });
  });
}
