import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdp/features/scan/data/tflite_prediction_repository.dart';
import 'package:pdp/features/scan/data/vegetation_color_screening.dart';

void main() {
  test('penyaring menolak sampel netral dan rona merah-oranye', () async {
    final photo = Uint8List(0);
    for (final color in [(92, 92, 92), (170, 110, 85)]) {
      final screening = VegetationColorScreening(_SolidColor(color));
      expect(await screening.accepts(photo), isFalse);
    }
  });

  test('penyaring menerima sampel hijau dan hijau kekuningan', () async {
    final photo = Uint8List(0);
    for (final color in [(58, 108, 49), (142, 130, 71)]) {
      final screening = VegetationColorScreening(_SolidColor(color));
      expect(await screening.accepts(photo), isTrue);
    }
  });
}

class _SolidColor implements PhotoPreprocessor {
  const _SolidColor(this.color);

  final (int, int, int) color;

  @override
  Future<Float32List> toInput(Uint8List photo, int inputSize) async {
    final pixels = Float32List(inputSize * inputSize * 3);
    for (var index = 0; index < pixels.length; index += 3) {
      pixels[index] = color.$1.toDouble();
      pixels[index + 1] = color.$2.toDouble();
      pixels[index + 2] = color.$3.toDouble();
    }
    return pixels;
  }
}
