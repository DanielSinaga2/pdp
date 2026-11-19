import 'dart:typed_data';

enum PhotoSource { gallery, camera }

abstract interface class PhotoRepository {
  /// Returns null when the user dismisses the picker.
  Future<Uint8List?> pickPhoto(PhotoSource source);

  /// Returns a pending Android picker result, if there is one.
  Future<Uint8List?> recoverPhoto();
}
