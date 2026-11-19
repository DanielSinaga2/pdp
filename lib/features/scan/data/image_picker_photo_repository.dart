import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:image_picker/image_picker.dart';

import '../domain/photo_repository.dart';

class ImagePickerPhotoRepository implements PhotoRepository {
  ImagePickerPhotoRepository(this._picker);

  final ImagePicker _picker;

  @override
  Future<Uint8List?> pickPhoto(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: switch (source) {
        PhotoSource.gallery => ImageSource.gallery,
        PhotoSource.camera => ImageSource.camera,
      },
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return file == null ? null : await _readPhoto(file);
  }

  @override
  Future<Uint8List?> recoverPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;

    final response = await _picker.retrieveLostData();
    if (response.isEmpty) return null;

    final exception = response.exception;
    if (exception != null) throw exception;

    final files = response.files;
    return files == null || files.isEmpty ? null : await _readPhoto(files.first);
  }

  Future<Uint8List> _readPhoto(XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        final frame = await codec.getNextFrame();
        frame.image.dispose();
      } finally {
        codec.dispose();
      }
      return bytes;
    } on Exception {
      throw const FormatException('Foto tidak dapat dibaca.');
    }
  }
}
