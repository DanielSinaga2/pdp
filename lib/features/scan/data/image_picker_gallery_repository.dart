import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image_picker/image_picker.dart';

import '../domain/gallery_repository.dart';

class ImagePickerGalleryRepository implements GalleryRepository {
  ImagePickerGalleryRepository(this._picker);

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } finally {
      codec.dispose();
    }

    return bytes;
  }
}
