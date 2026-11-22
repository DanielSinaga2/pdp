import 'dart:typed_data';

import '../domain/prediction_repository.dart';
import 'prediction_postprocessing.dart';

/// Kegagalan memuat atau menjalankan model. Sengaja berupa [Exception]
/// (bukan Error) agar tertangkap oleh `on Exception` di ScanBloc.
class ModelException implements Exception {
  const ModelException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ModelException: $message${cause == null ? '' : ' ($cause)'}';
}

/// Metadata model dari `pemetaan.json` (dihasilkan notebook pelatihan).
class ModelSpec {
  const ModelSpec({required this.classes, required this.inputSize});

  /// Urutan kelas sesuai keluaran model.
  final List<String> classes;

  /// Sisi gambar persegi yang diharapkan model (piksel).
  final int inputSize;

  factory ModelSpec.fromJson(Map<String, dynamic> json) {
    final rawClasses = json['kelas'];
    final rawSize = json['img'];
    if (rawClasses is! List || rawClasses.isEmpty) {
      throw const FormatException('pemetaan.json: "kelas" kosong atau hilang.');
    }
    if (rawSize is! int || rawSize < 32 || rawSize > 1024) {
      throw const FormatException('pemetaan.json: "img" tidak valid.');
    }
    final classes = [for (final item in rawClasses) item.toString()];
    if (classes.toSet().length != classes.length) {
      throw const FormatException('pemetaan.json: nama kelas ganda.');
    }
    if (!classes.any(kModelClassToLabel.containsKey)) {
      throw FormatException(
        'pemetaan.json: tidak ada kelas yang dikenal aplikasi '
        '(${kModelClassToLabel.keys.join(', ')}).',
      );
    }
    return ModelSpec(classes: classes, inputSize: rawSize);
  }
}

/// Menjalankan model. Implementasi perangkat ada di `tflite_platform.dart`.
abstract interface class ClassifierBackend {
  /// [input] berukuran inputSize*inputSize*3 (RGB, nilai 0..255, baris demi baris).
  Future<List<double>> run(Float32List input, ModelSpec spec);

  void close();
}

/// Mengubah bytes foto menjadi masukan model.
abstract interface class PhotoPreprocessor {
  /// Mengembalikan inputSize*inputSize*3 nilai float 0..255 (RGB).
  Future<Float32List> toInput(Uint8List photo, int inputSize);
}

/// Prediksi on-device memakai model TFLite hasil pelatihan.
///
/// Pemuatan model dilakukan malas (saat analisis pertama) dan hasilnya
/// disimpan; pemuatan yang gagal tidak di-cache sehingga bisa dicoba ulang.
class TflitePredictionRepository implements PredictionRepository {
  TflitePredictionRepository({
    required Future<ModelSpec> Function() loadSpec,
    required Future<ClassifierBackend> Function(ModelSpec spec) loadBackend,
    required PhotoPreprocessor preprocessor,
    void Function(String message)? log,
  }) : _loadSpec = loadSpec,
       _loadBackend = loadBackend,
       _preprocessor = preprocessor,
       _log = log;

  final Future<ModelSpec> Function() _loadSpec;
  final Future<ClassifierBackend> Function(ModelSpec spec) _loadBackend;
  final PhotoPreprocessor _preprocessor;
  final void Function(String message)? _log;

  Future<(ModelSpec, ClassifierBackend)>? _loading;
  ClassifierBackend? _backend;

  Future<(ModelSpec, ClassifierBackend)> _ensureLoaded() {
    return _loading ??= _load().catchError((Object error) {
      _loading = null;
      throw error;
    });
  }

  Future<(ModelSpec, ClassifierBackend)> _load() async {
    try {
      final spec = await _loadSpec();
      final backend = await _loadBackend(spec);
      _backend = backend;
      return (spec, backend);
    } on Exception catch (error) {
      _log?.call('Gagal memuat model: $error');
      throw ModelException('Model tidak dapat dimuat.', error);
    } catch (error) {
      _log?.call('Gagal memuat model: $error');
      throw ModelException('Model tidak dapat dimuat.', error);
    }
  }

  @override
  Future<ScanPrediction> predict(Uint8List photo) async {
    final (spec, backend) = await _ensureLoaded();
    try {
      final input = await _preprocessor.toInput(photo, spec.inputSize);
      final expected = spec.inputSize * spec.inputSize * 3;
      if (input.length != expected) {
        throw FormatException(
          'Ukuran masukan ${input.length}, seharusnya $expected.',
        );
      }
      final raw = await backend.run(input, spec);
      return pickPrediction(spec.classes, toProbabilities(raw));
    } on Exception catch (error) {
      _log?.call('Prediksi gagal: $error');
      rethrow;
    } catch (error) {
      // Error non-Exception (mis. dari plugin) dibungkus agar ScanBloc
      // tidak membiarkan status "menganalisis" menggantung.
      _log?.call('Prediksi gagal: $error');
      throw ModelException('Model gagal dijalankan.', error);
    }
  }

  void dispose() {
    _backend?.close();
    _backend = null;
    _loading = null;
  }
}
