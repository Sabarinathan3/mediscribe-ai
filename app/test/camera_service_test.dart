import 'package:flutter_test/flutter_test.dart';
import 'package:mediscribe_app/services/camera_service.dart';
import 'package:mediscribe_app/services/image_picker_service.dart';

void main() {
  group('CameraException', () {
    test('toString returns user-facing message', () {
      const message = 'Camera access was denied. Please enable camera permissions in your settings.';
      final error = CameraException(message);
      expect(error.toString(), message);
    });
  });

  group('ImagePickerException', () {
    test('toString returns user-facing message', () {
      const message = 'Gallery access was denied. Please enable gallery permissions in your settings.';
      final error = ImagePickerException(message);
      expect(error.toString(), message);
    });
  });
}
