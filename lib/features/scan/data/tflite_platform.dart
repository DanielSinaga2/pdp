import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_litert/flutter_litert.dart';

import 'tflite_prediction_repository.dart';

/// Berkas yang dihasilkan notebook + `tools/konversi_tflite.py`.
const String kModelAsset = 'assets/model/model_image.tflite';
const String kModelSpecAsset = 'assets/model/pemetaan.json';

/// Membaca `pemetaan.json` (urutan kelas dan ukuran gambar) dari asset.
Future<ModelSpec> loadModelSpec({String asset = kModelSpecAsset}) async {
  final json = jsonDecode(await rootBundle.loadString(asset));
  if (json is! Map<String, dynamic>) {
    throw const FormatException('pemetaan.json bukan objek JSON.');
  }
  return ModelSpec.fromJson(json);
}

/// Menjalankan model TFLite lewat LiteRT (pengganti tflite_flutter).
class LiteRtClassifierBackend implements ClassifierBackend {
  LiteRtClassifierBackend._(this._interpreter);

  final Interpreter _interpreter;

  static Future<LiteRtClassifierBackend> load(
    ModelSpec spec, {
    String asset = kModelAsset,
  }) async {
    final interpreter = await Interpreter.fromAsset(asset);
    try {
      _validate(interpreter, spec);
    } catch (_) {
      interpreter.close();
      rethrow;
    }
    return LiteRtClassifierBackend._(interpreter);
  }

  /// Memastikan bentuk tensor model cocok dengan pemetaan.json sehingga salah
  /// pasang berkas (mis. model 5 kelas dengan pemetaan 10 kelas) langsung
  /// ketahuan, bukan menghasilkan label yang salah secara diam-diam.
  static void _validate(Interpreter interpreter, ModelSpec spec) {
    final inShape = interpreter.getInputTensors().first.shape;
    final outShape = interpreter.getOutputTensors().first.shape;
    final size = spec.inputSize;
    final okInput =
        inShape.length == 4 &&
        inShape[1] == size &&
        inShape[2] == size &&
        inShape[3] == 3;
    if (!okInput) {
      throw ModelException(
        'Bentuk masukan model $inShape tidak cocok dengan pemetaan.json '
        '([1, $size, $size, 3]).',
      );
    }
    if (outShape.last != spec.classes.length) {
      throw ModelException(
        'Model memiliki ${outShape.last} keluaran, pemetaan.json memiliki '
        '${spec.classes.length} kelas.',
      );
    }
  }

  @override
  Future<List<double>> run(Float32List input, ModelSpec spec) async {
    final count = spec.classes.length;
    final output = List.filled(count, 0.0).reshape([1, count]);
    // Float32List dikirim apa adanya (tanpa salinan); bentuk [1, size, size, 3]
    // sudah dijamin oleh _validate dan oleh pemeriksaan ukuran di repositori.
    _interpreter.run(input, output);
    return [for (final value in output[0] as List) (value as num).toDouble()];
  }

  @override
  void close() => _interpreter.close();
}

/// Praproses foto: ubah ukuran ke persegi (tanpa menjaga rasio, sama dengan
/// pelatihan), ambil RGB, nilai 0..255. Penskalaan lanjutan ada di dalam model.
class UiPhotoPreprocessor implements PhotoPreprocessor {
  const UiPhotoPreprocessor();

  @override
  Future<Float32List> toInput(Uint8List photo, int inputSize) async {
    final codec = await ui.instantiateImageCodec(
      photo,
      targetWidth: inputSize,
      targetHeight: inputSize,
    );
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        if (image.width != inputSize || image.height != inputSize) {
          throw FormatException(
            'Ukuran hasil resize ${image.width}x${image.height}, '
            'seharusnya ${inputSize}x$inputSize.',
          );
        }
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data == null) {
          throw const FormatException('Foto tidak dapat diproses.');
        }
        final rgba = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        final input = Float32List(inputSize * inputSize * 3);
        var out = 0;
        for (var i = 0; i < rgba.length; i += 4) {
          input[out++] = rgba[i].toDouble();
          input[out++] = rgba[i + 1].toDouble();
          input[out++] = rgba[i + 2].toDouble();
        }
        return input;
      } finally {
        image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }
}

/// Repositori prediksi on-device siap pakai untuk dipasang di `injection.dart`.
TflitePredictionRepository createTflitePredictionRepository() {
  return TflitePredictionRepository(
    loadSpec: loadModelSpec,
    loadBackend: LiteRtClassifierBackend.load,
    preprocessor: const UiPhotoPreprocessor(),
    log: debugPrint,
  );
}
