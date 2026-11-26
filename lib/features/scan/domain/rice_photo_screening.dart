import 'dart:typed_data';

abstract interface class RicePhotoScreening {
  Future<bool> accepts(Uint8List photo);
}

class UnsuitableRicePhoto implements Exception {
  const UnsuitableRicePhoto();
}
