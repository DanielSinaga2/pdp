import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/knowledge/data/local_disease_detail_repository.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';
import 'package:pdp/features/scan/domain/prediction_repository.dart';
import 'package:pdp/features/scan/presentation/ai_analysis_detail_page.dart';
import 'package:pdp/features/scan/presentation/scan_result_page.dart';

final _photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMwK3YGAAHPAO2uH13mAAAAAElFTkSuQmCC',
);

void main() {
  const details = LocalDiseaseDetailRepository();

  testWidgets('tombol membuka detail dan kembali mempertahankan hasil', (
    tester,
  ) async {
    final prediction = ScanPrediction(
      label: ConditionLabel.blast,
      confidence: 0.91,
      isSimulated: false,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultPage(
          photo: _photo,
          prediction: prediction,
          detail: details.getDetail(prediction.label),
        ),
      ),
    );

    await _ensureVisible(tester, find.text('Lihat Detail AI & Penanganan'));
    expect(find.text('Lihat Detail AI & Penanganan'), findsOneWidget);
    await tester.tap(find.text('Lihat Detail AI & Penanganan'));
    await tester.pumpAndSettle();

    expect(find.text('Detail AI & Penanganan'), findsOneWidget);
    expect(find.text('PaddySehat Image Classification Model'), findsOneWidget);
    expect(find.text('TensorFlow Lite'), findsOneWidget);
    expect(
      find.textContaining('Notebook menggunakan EfficientNetB0'),
      findsOneWidget,
    );
    expect(find.text('On-device inference'), findsOneWidget);
    await _ensureVisible(tester, find.text('Foto daun padi'));
    expect(find.text('Foto daun padi'), findsOneWidget);
    await _ensureVisible(
      tester,
      find.text('Klasifikasi kondisi atau penyakit daun padi'),
    );
    expect(
      find.text('Klasifikasi kondisi atau penyakit daun padi'),
      findsOneWidget,
    );
    await _ensureVisible(tester, find.text('Model asli (TensorFlow Lite)'));
    expect(find.text('Model asli (TensorFlow Lite)'), findsOneWidget);
    await _ensureVisible(tester, find.text('Blast').first);
    expect(find.text('Blast').first, findsOneWidget);
    await _ensureVisible(tester, find.textContaining('Tanam varietas tahan'));
    expect(find.textContaining('Tanam varietas tahan'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hasil analisis'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.text('Blast'), findsOneWidget);
    await _ensureVisible(tester, find.text('Lihat Detail AI & Penanganan'));
    expect(find.text('Lihat Detail AI & Penanganan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rekomendasi mengikuti label dan kondisi sehat dirawat', (
    tester,
  ) async {
    for (final (label, expectedText) in [
      (ConditionLabel.bacterialLeafBlight, 'Gunakan varietas yang tahan'),
      (ConditionLabel.blast, 'Tanam varietas tahan'),
      (ConditionLabel.brownSpot, 'Gunakan benih sehat'),
      (ConditionLabel.tungro, 'Gunakan varietas tahan'),
      (ConditionLabel.healthy, 'Lanjutkan pemantauan rutin'),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: AiAnalysisDetailPage(
            photo: null,
            prediction: ScanPrediction(
              label: label,
              confidence: 0.88,
              isSimulated: false,
            ),
            detail: details.getDetail(label),
            confidencePercent: 75,
          ),
        ),
      );

      expect(find.text('Detail AI & Penanganan'), findsOneWidget);
      await _ensureVisible(tester, find.textContaining(expectedText));
      expect(find.textContaining(expectedText), findsOneWidget);
      if (label == ConditionLabel.healthy) {
        expect(find.text('Rekomendasi Penanganan'), findsNothing);
      } else {
        expect(find.text('Perawatan Tanaman'), findsNothing);
      }
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('confidence rendah memperingatkan dan status simulasi tampil', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultPage(
          photo: _photo,
          prediction: const ScanPrediction(
            label: ConditionLabel.brownSpot,
            confidence: 0.62,
            isSimulated: true,
          ),
          detail: details.getDetail(ConditionLabel.brownSpot),
        ),
      ),
    );
    await _ensureVisible(tester, find.text('Lihat Detail AI & Penanganan'));
    await tester.tap(find.text('Lihat Detail AI & Penanganan'));
    await tester.pumpAndSettle();

    await _ensureVisible(tester, find.text('Simulasi'));
    expect(find.text('Simulasi'), findsOneWidget);
    await _ensureVisible(
      tester,
      find.textContaining('Confidence CNN di bawah 75%'),
    );
    expect(find.textContaining('Confidence CNN di bawah 75%'), findsOneWidget);
    expect(find.textContaining('bersifat awal'), findsOneWidget);
    expect(find.textContaining('penyuluh'), findsOneWidget);
    await _ensureVisible(
      tester,
      find.textContaining('bukan pengganti pemeriksaan langsung'),
    );
    expect(
      find.textContaining('bukan pengganti pemeriksaan langsung'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('detail tetap dapat ditampilkan pada layar sempit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AiAnalysisDetailPage(
          photo: null,
          prediction: const ScanPrediction(
            label: ConditionLabel.tungro,
            confidence: 0.84,
            isSimulated: false,
          ),
          detail: details.getDetail(ConditionLabel.tungro),
          confidencePercent: 75,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail AI & Penanganan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('input gejala dan fuzzy tidak terisi otomatis', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiAnalysisDetailPage(
          photo: null,
          prediction: const ScanPrediction(
            label: ConditionLabel.blast,
            confidence: 0.82,
            isSimulated: false,
          ),
          detail: details.getDetail(ConditionLabel.blast),
          confidencePercent: 75,
          diseaseDetails: details,
        ),
      ),
    );

    await _ensureVisible(
      tester,
      find.text(
        'CF belum dapat dihitung karena belum ada evidence yang dipilih.',
      ),
    );
    expect(
      find.text(
        'CF belum dapat dihitung karena belum ada evidence yang dipilih.',
      ),
      findsOneWidget,
    );
    await _ensureVisible(
      tester,
      find.byKey(const ValueKey('fuzzy_Keparahan gejala')),
    );
    expect(
      find.byKey(const ValueKey('fuzzy_Keparahan gejala')),
      findsOneWidget,
    );
    await _ensureVisible(
      tester,
      find.byKey(const ValueKey('fuzzy_Umur tanaman (HST)')),
    );
    expect(
      find.byKey(const ValueKey('fuzzy_Umur tanaman (HST)')),
      findsOneWidget,
    );
    await _ensureVisible(
      tester,
      find.byKey(const ValueKey('fuzzy_Kelembapan udara (RH)')),
    );
    expect(
      find.byKey(const ValueKey('fuzzy_Kelembapan udara (RH)')),
      findsOneWidget,
    );
    await _ensureVisible(
      tester,
      find.text('Lengkapi input keparahan, HST, dan RH.'),
    );
    expect(find.text('Lengkapi input keparahan, HST, dan RH.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pertanyaan gejala adaptif dan gejala tambahan dapat dibuka', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AiAnalysisDetailPage(
          photo: null,
          prediction: const ScanPrediction(
            label: ConditionLabel.blast,
            confidence: 0.82,
            isSimulated: false,
          ),
          detail: details.getDetail(ConditionLabel.blast),
          confidencePercent: 75,
        ),
      ),
    );

    await _ensureVisible(tester, find.text('Bercak berbentuk belah ketupat'));
    expect(find.text('Bercak berbentuk belah ketupat'), findsOneWidget);
    await _ensureVisible(
      tester,
      find.text('Garis basah/kekuningan memanjang di tepi daun'),
    );
    expect(
      find.text('Garis basah/kekuningan memanjang di tepi daun'),
      findsOneWidget,
    );
    expect(find.text('Tanaman kerdil dan anakan sedikit'), findsNothing);
    await _ensureVisible(
      tester,
      find.text('Terjawab: 0 dari 9 pertanyaan yang ditampilkan'),
    );
    expect(
      find.text('Terjawab: 0 dari 9 pertanyaan yang ditampilkan'),
      findsOneWidget,
    );

    await _selectDropdown(tester, const ValueKey('symptom_G05'), 'Ragu (0.4)');
    await _ensureVisible(
      tester,
      find.text('Terjawab: 1 dari 9 pertanyaan yang ditampilkan'),
    );
    expect(
      find.text('Terjawab: 1 dari 9 pertanyaan yang ditampilkan'),
      findsOneWidget,
    );

    final additionalSymptoms = find.text('Lihat gejala tambahan (7)');
    await _ensureVisible(tester, additionalSymptoms);
    await tester.tap(additionalSymptoms);
    await tester.pumpAndSettle();
    await _ensureVisible(
      tester,
      find.text('Tanaman kerdil dan anakan sedikit'),
    );
    expect(find.text('Tanaman kerdil dan anakan sedikit'), findsOneWidget);
    await _ensureVisible(
      tester,
      find.text('Terjawab: 1 dari 16 pertanyaan yang ditampilkan'),
    );
    expect(
      find.text('Terjawab: 1 dari 16 pertanyaan yang ditampilkan'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hasil fuzzy kembali ke hasil scan tanpa prediksi ulang', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ScanResultPage(
          photo: null,
          prediction: const ScanPrediction(
            label: ConditionLabel.blast,
            confidence: 0.86,
            isSimulated: false,
          ),
          detail: details.getDetail(ConditionLabel.blast),
          diseaseDetails: details,
        ),
      ),
    );
    await _ensureVisible(tester, find.text('Lihat Detail AI & Penanganan'));
    await tester.tap(find.text('Lihat Detail AI & Penanganan'));
    await tester.pumpAndSettle();

    await _selectDropdown(
      tester,
      const ValueKey('symptom_G05'),
      'Sangat yakin (1.0)',
    );
    await _enterField(tester, const ValueKey('fuzzy_Keparahan gejala'), '0');
    await _enterField(tester, const ValueKey('fuzzy_Umur tanaman (HST)'), '0');
    await _enterField(
      tester,
      const ValueKey('fuzzy_Kelembapan udara (RH)'),
      '50',
    );

    await _ensureVisible(
      tester,
      find.textContaining('Faktor Urea Sugeno: 0.80'),
    );
    expect(find.textContaining('Faktor Urea Sugeno: 0.80'), findsOneWidget);
    expect(find.textContaining('Faktor KCl Sugeno: 1.30'), findsOneWidget);

    final backToResult = find.text('Kembali ke Hasil Analisis');
    await _ensureVisible(tester, backToResult);
    await tester.tap(backToResult);
    await tester.pumpAndSettle();
    expect(find.text('Hasil analisis'), findsOneWidget);
    await _ensureVisible(tester, find.text('Input keparahan: 0%'));
    expect(find.text('Input keparahan: 0%'), findsOneWidget);
    expect(find.text('Skor Sugeno: 0.20'), findsOneWidget);
    expect(find.text('Blast'), findsWidgets);

    final openDetail = find.text('Lihat Detail AI & Penanganan');
    await _ensureVisible(tester, openDetail);
    await tester.tap(openDetail);
    await tester.pumpAndSettle();

    final symptom = find.byKey(const ValueKey('symptom_G05'));
    await _ensureVisible(tester, symptom);
    expect(
      find.descendant(
        of: symptom,
        matching: find.text('Sangat yakin (1.0)'),
      ),
      findsOneWidget,
    );
    for (final (label, value) in [
      ('Keparahan gejala', '0'),
      ('Umur tanaman (HST)', '0'),
      ('Kelembapan udara (RH)', '50'),
    ]) {
      final field = find.byKey(ValueKey('fuzzy_$label'));
      await _ensureVisible(tester, field);
      final input = find.descendant(
        of: field,
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(input).controller.text, value);
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _ensureVisible(WidgetTester tester, Finder finder) async {
  for (final delta in [const Offset(0, -400), const Offset(0, 400)]) {
    for (var attempt = 0; attempt < 30; attempt++) {
      if (finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        return;
      }
      final listViews = find.byType(ListView);
      if (listViews.evaluate().isEmpty) return;
      await tester.drag(listViews.last, delta);
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _selectDropdown(
  WidgetTester tester,
  Key dropdownKey,
  String option,
) async {
  final dropdown = find.byKey(dropdownKey);
  await _ensureVisible(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Future<void> _enterField(
  WidgetTester tester,
  Key fieldKey,
  String value,
) async {
  final field = find.byKey(fieldKey);
  await _ensureVisible(tester, field);
  await tester.enterText(field, value);
  await tester.pumpAndSettle();
}
