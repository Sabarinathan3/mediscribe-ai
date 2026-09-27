import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mediscribe_app/services/upload_provider.dart';

class MockDio extends Mock implements Dio {}
class MockXFile extends Mock implements XFile {}

void main() {
  late UploadNotifier notifier;
  late MockDio mockDio;
  late MockXFile mockXFile;
  late File tempFile;

  setUp(() {
    mockDio = MockDio();
    mockXFile = MockXFile();
    notifier = UploadNotifier(mockDio);
    
    // Create a temporary file so MultipartFile.fromFile succeeds
    tempFile = File('test_path.jpg');
    tempFile.writeAsStringSync('dummy content');
    
    when(() => mockXFile.path).thenReturn(tempFile.path);
    when(() => mockXFile.name).thenReturn('test_path.jpg');
    
    registerFallbackValue(RequestOptions(path: ''));
  });

  tearDown(() {
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
  });

  group('UploadNotifier', () {
    test('uploadAndProcessPrescription() successfully parses multipart response', () async {
      final responseData = {'result': 'success'};
      
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/ai/process-prescription'),
                statusCode: 200,
                data: responseData,
              ));

      expect(notifier.state, isA<UploadIdle>());
      
      // We don't await here because we want to check the intermediate states if possible,
      // but state notifier tests usually just check the final state after await.
      await notifier.uploadAndProcessPrescription(mockXFile);

      expect(notifier.state, isA<OCRSuccess>());
      final successState = notifier.state as OCRSuccess;
      expect(successState.responseData, responseData);
    });

    test('uploadAndProcessPrescription() handles network timeout (connectionTimeout)', () async {
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(path: ''),
            type: DioExceptionType.connectionTimeout,
            message: 'Connection timed out',
          ));

      await notifier.uploadAndProcessPrescription(mockXFile);

      expect(notifier.state, isA<UploadError>());
      final errorState = notifier.state as UploadError;
      expect(errorState.errorMessage, contains('Connection timed out'));
    });

    test('uploadAndProcessPrescription() fires upload progress callback correctly', () async {
      // Simulate progress callback
      when(() => mockDio.post(
            any(),
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
            onSendProgress: any(named: 'onSendProgress'),
          )).thenAnswer((Invocation invocation) async {
        final onSendProgress = invocation.namedArguments[#onSendProgress] as ProgressCallback?;
        if (onSendProgress != null) {
          onSendProgress(50, 100); // 50%
        }
        return Response(
          requestOptions: RequestOptions(path: ''),
          statusCode: 200,
          data: {},
        );
      });

      // To capture the intermediate state, we can listen to the notifier
      final states = <UploadState>[];
      notifier.addListener((state) {
        states.add(state);
      });

      await notifier.uploadAndProcessPrescription(mockXFile);

      // Verify progress was reported
      final progressState = states.whereType<UploadProgress>().last;
      expect(progressState.percentage, (50 / 100) * 0.95);
    });
  });
}
