import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';
import 'package:pdp/features/scan/data/tflite_prediction_repository.dart';

const _classes = ['blast', 'brown_spot', 'hispa', 'normal', 'tungro'];
const _spec = ModelSpec(classes: _classes, inputSize: 32);

class _FakeBackend implements ClassifierBackend {
  _FakeBackend(this.output);

  List<double> output;
  Object? error;
  int runs = 0;
  bool closed = false;
  Float32List? lastInput;

  @override
  Future<List<double>> run(Float32List input, ModelSpec spec) async {
    runs++;
    lastInput = input;
    if (error != null) throw error!;
    return output;
  }

  @override
  void close() => closed = true;
}

class _FakePreprocessor implements PhotoPreprocessor {
  _FakePreprocessor({this.length});

  final int? length;

  @override
  Future<Float32List> toInput(Uint8List photo, int inputSize) async =>
      Float32List(length ?? inputSize * inputSize * 3);
}

TflitePredictionRepository _repository(
  _FakeBackend backend, {
  PhotoPreprocessor? preprocessor,
  Future<ClassifierBackend> Function(ModelSpec)? loadBackend,
  void Function(String)? log,
}) {
  return TflitePredictionRepository(
    loadSpec: () async => _spec,
    loadBackend: loadBackend ?? (_) async => backend,
    preprocessor: preprocessor ?? _FakePreprocessor(),
    log: log,
  );
}

void main() {
  final photo = Uint8List.fromList([1, 2, 3]);

  group('ModelSpec.fromJson', () {
    test('membaca kelas dan ukuran gambar', () {
      final spec = ModelSpec.fromJson({
        'kelas': ['blast', 'normal'],
        'img': 224,
      });
      expect(spec.classes, ['blast', 'normal']);
      expect(spec.inputSize, 224);
    });

    test('menolak data tidak valid', () {
      expect(() => ModelSpec.fromJson({'img': 224}), throwsFormatException);
      expect(
        () => ModelSpec.fromJson({
          'kelas': ['blast'],
          'img': 8,
        }),
        throwsFormatException,
      );
      expect(
        () => ModelSpec.fromJson({
          'kelas': ['blast', 'blast'],
          'img': 224,
        }),
        throwsFormatException,
      );
      expect(
        () => ModelSpec.fromJson({
          'kelas': ['hispa'],
          'img': 224,
        }),
        throwsFormatException,
      );
    });
  });

  group('TflitePredictionRepository', () {
    test('menghasilkan prediksi dari keluaran model', () async {
      final backend = _FakeBackend([0.05, 0.9, 0.02, 0.02, 0.01]);
      final prediction = await _repository(backend).predict(photo);

      expect(prediction.label, ConditionLabel.brownSpot);
      expect(prediction.confidence, closeTo(0.9, 1e-9));
      expect(prediction.isSimulated, isFalse);
      expect(backend.lastInput!.length, 32 * 32 * 3);
    });

    test('memuat model sekali untuk beberapa prediksi', () async {
      final backend = _FakeBackend([0.9, 0.05, 0.02, 0.02, 0.01]);
      var loads = 0;
      final repository = _repository(
        backend,
        loadBackend: (_) async {
          loads++;
          return backend;
        },
      );

      await repository.predict(photo);
      await repository.predict(photo);

      expect(loads, 1);
      expect(backend.runs, 2);
    });

    test(
      'kegagalan memuat dibungkus ModelException dan boleh dicoba ulang',
      () async {
        final backend = _FakeBackend([0.9, 0.05, 0.02, 0.02, 0.01]);
        var attempts = 0;
        final logs = <String>[];
        final repository = _repository(
          backend,
          log: logs.add,
          loadBackend: (_) async {
            attempts++;
            if (attempts == 1) throw StateError('berkas tidak ada');
            return backend;
          },
        );

        await expectLater(
          repository.predict(photo),
          throwsA(isA<ModelException>()),
        );
        expect(logs, isNotEmpty);
        final prediction = await repository.predict(photo);
        expect(prediction.label, ConditionLabel.blast);
      },
    );

    test(
      'Error non-Exception dari model dibungkus agar tertangkap ScanBloc',
      () async {
        final backend = _FakeBackend([0.9, 0.05, 0.02, 0.02, 0.01])
          ..error = StateError('native crash');
        await expectLater(
          _repository(backend).predict(photo),
          throwsA(isA<ModelException>()),
        );
      },
    );

    test('menolak ukuran masukan dari preprocessor yang salah', () async {
      final backend = _FakeBackend([0.9, 0.05, 0.02, 0.02, 0.01]);
      final repository = _repository(
        backend,
        preprocessor: _FakePreprocessor(length: 10),
      );
      await expectLater(repository.predict(photo), throwsFormatException);
      expect(backend.runs, 0);
    });

    test('menolak keluaran model dengan jumlah kelas berbeda', () async {
      final backend = _FakeBackend([0.5, 0.5]);
      await expectLater(
        _repository(backend).predict(photo),
        throwsFormatException,
      );
    });

    test('dispose menutup backend', () async {
      final backend = _FakeBackend([0.9, 0.05, 0.02, 0.02, 0.01]);
      final repository = _repository(backend);
      await repository.predict(photo);
      repository.dispose();
      expect(backend.closed, isTrue);
    });
  });
}
