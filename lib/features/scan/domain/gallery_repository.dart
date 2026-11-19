import 'dart:typed_data';

abstract interface class GalleryRepository {
  /// Returns null when the user dismisses the picker.
  Future<Uint8List?> pickPhoto();
}
