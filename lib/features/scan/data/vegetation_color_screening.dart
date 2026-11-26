import 'dart:typed_data';

import '../domain/rice_photo_screening.dart';
import 'tflite_prediction_repository.dart';

/// Temporary color check until an on-device rice-leaf validator is available.
/// The score estimates visible green or yellow-green pixels, not the species.
class VegetationColorScreening implements RicePhotoScreening {
  const VegetationColorScreening(this._preprocessor);

  final PhotoPreprocessor _preprocessor;

  static const _sampleSize = 40;
  static const _minimumFraction = 0.04;

  @override
  Future<bool> accepts(Uint8List photo) async {
    final rgb = await _preprocessor.toInput(photo, _sampleSize);
    var vegetationPixels = 0;
    for (var offset = 0; offset < rgb.length; offset += 3) {
      final red = rgb[offset];
      final green = rgb[offset + 1];
      final blue = rgb[offset + 2];

      // Keep green and olive tones, including yellowing leaves. The blue
      // separation avoids counting neutral, near-black and gray pixels.
      if (green >= 30 && green - blue >= 12 && green >= red * 0.88) {
        vegetationPixels++;
      }
    }
    return vegetationPixels >= _sampleSize * _sampleSize * _minimumFraction;
  }
}
