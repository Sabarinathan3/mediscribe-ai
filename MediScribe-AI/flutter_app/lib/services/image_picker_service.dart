import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerException implements Exception {
  final String message;
  ImagePickerException(this.message);

  @override
  String toString() => message;
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      return image;
    } on PlatformException catch (e) {
      if (e.code == 'photo_access_denied') {
        throw ImagePickerException('Gallery access was denied. Please enable gallery permissions in your settings.');
      }
      throw ImagePickerException('Failed to pick image: ${e.message}');
    } catch (e) {
      throw ImagePickerException('An unexpected gallery error occurred.');
    }
  }
}
