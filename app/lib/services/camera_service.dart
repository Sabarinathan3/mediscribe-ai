import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CameraException implements Exception {
  final String message;
  CameraException(this.message);

  @override
  String toString() => message;
}

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      return photo;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw CameraException('Camera access was denied. Please enable camera permissions in your settings.');
      }
      throw CameraException('Failed to capture photo: ${e.message}');
    } catch (e) {
      throw CameraException('An unexpected camera error occurred.');
    }
  }
}
