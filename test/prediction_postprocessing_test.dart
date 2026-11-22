import 'package:flutter_test/flutter_test.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';
import 'package:pdp/features/scan/data/prediction_postprocessing.dart';

void main() {
  group('toProbabilities', () {
    test('mempertahankan distribusi probabilitas yang sudah valid', () {
      expect(toProbabilities([0.1, 0.7, 0.2]), [0.1, 0.7, 0.2]);
    });

    test('menerapkan softmax pada logit', () {
      final result = toProbabilities([2.0, 1.0, 0.1]);
      expect(result.fold<double>(0, (a, b) => a + b), closeTo(1.0, 1e-9));
      expect(result[0], greaterThan(result[1]));
      expect(result[1], greaterThan(result[2]));
    });

    test('stabil untuk logit besar', () {
      final result = toProbabilities([1000.0, 1001.0]);
      expect(result[1], closeTo(0.731, 1e-3));
    });

    test('menolak keluaran kosong atau tidak valid', () {
      expect(() => toProbabilities([]), throwsFormatException);
      expect(() => toProbabilities([double.nan, 0.5]), throwsFormatException);
    });
  });

  group('pickPrediction', () {
    const classes = [
      'bacterial_leaf_blight',
      'blast',
      'brown_spot',
      'hispa',
      'normal',
      'tungro',
    ];

    test('memilih label dengan probabilitas tertinggi', () {
      final prediction = pickPrediction(classes, [
        0.02,
        0.9,
        0.03,
        0.0,
        0.02,
        0.03,
      ]);
      expect(prediction.label, ConditionLabel.blast);
      expect(prediction.confidence, closeTo(0.9, 1e-9));
      expect(prediction.isSimulated, isFalse);
    });

    test('memetakan kelas normal ke healthy', () {
      final prediction = pickPrediction(classes, [
        0.0,
        0.05,
        0.0,
        0.0,
        0.9,
        0.05,
      ]);
      expect(prediction.label, ConditionLabel.healthy);
    });

    test('kelas di luar cakupan menurunkan keyakinan, bukan dibuang', () {
      // model yakin "hispa" (tidak dikenal aplikasi): label terbaik yang dikenal
      // hanya mendapat 0.25 sehingga halaman hasil akan memberi peringatan.
      final prediction = pickPrediction(classes, [
        0.05,
        0.25,
        0.05,
        0.6,
        0.03,
        0.02,
      ]);
      expect(prediction.label, ConditionLabel.blast);
      expect(prediction.confidence, closeTo(0.25, 1e-9));
    });

    test('menjumlahkan kelas yang dipetakan ke label yang sama', () {
      final prediction = pickPrediction(
        ['normal', 'healthy', 'blast'],
        [0.3, 0.3, 0.4],
      );
      expect(prediction.label, ConditionLabel.healthy);
      expect(prediction.confidence, closeTo(0.6, 1e-9));
    });

    test(
      'menolak jumlah keluaran yang tidak cocok atau tanpa kelas dikenal',
      () {
        expect(
          () => pickPrediction(classes, [0.5, 0.5]),
          throwsFormatException,
        );
        expect(
          () => pickPrediction(['hispa', 'dead_heart'], [0.5, 0.5]),
          throwsFormatException,
        );
      },
    );
  });
}
