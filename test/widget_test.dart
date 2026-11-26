import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/history/domain/history_repository.dart';
import 'package:pdp/features/knowledge/data/local_disease_detail_repository.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';
import 'package:pdp/features/knowledge/domain/disease_detail_repository.dart';
import 'package:pdp/features/scan/data/simulated_prediction_repository.dart';
import 'package:pdp/features/scan/domain/photo_repository.dart';
import 'package:pdp/features/scan/domain/prediction_repository.dart';
import 'package:pdp/features/scan/domain/rice_photo_screening.dart';
import 'package:pdp/features/scan/domain/scan_photo.dart';
import 'package:pdp/features/scan/presentation/scan_bloc.dart';
import 'package:pdp/features/scan/presentation/scan_page.dart';
import 'package:pdp/features/scan/presentation/scan_result_page.dart';
import 'package:pdp/features/settings/domain/settings_repository.dart';
import 'package:pdp/features/settings/presentation/settings_cubit.dart';
import 'package:pdp/injection.dart';
import 'package:pdp/main.dart';

final _photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMwK3YGAAHPAO2uH13mAAAAAElFTkSuQmCC',
);

void main() {
  const details = LocalDiseaseDetailRepository();
  const warning = 'Hasil kurang meyakinkan. Coba ambil foto ulang '
      'dengan pencahayaan yang lebih baik.';

  testWidgets('aplikasi dibuka di Beranda dan Scan membuka halaman kamera', (
    tester,
  ) async {
    final history = _History();
    getIt.registerSingleton<HistoryRepository>(history);
    getIt.registerSingleton<DiseaseDetailRepository>(details);
    getIt.registerFactory(() => SettingsCubit(_DefaultSettings())..load());
    getIt.registerFactory(
      () => ScanBloc(
        _Photos((_) async => null),
        ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
        history,
      ),
    );
    addTearDown(getIt.reset);

    await tester.pumpWidget(const PadiSehatApp());
    await tester.pumpAndSettle();

    expect(find.text('Fitur'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.byType(ScanPage), findsNothing);
    expect(find.text('Ambil Foto'), findsNothing);

    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.byType(ScanPage), findsOneWidget);
    expect(find.text('Scan daun padi'), findsOneWidget);
    expect(find.text('Pilih Foto dari Galeri'), findsOneWidget);
    expect(find.text('Ambil Foto'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Fitur'), findsOneWidget);
    expect(find.byType(ScanPage), findsNothing);

    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat scan.'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pengaturan'));
    await tester.pumpAndSettle();
    expect(find.text('Ambang tingkat keyakinan'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('lima label memiliki materi lokal yang lengkap dan ditandai untuk ditinjau', () {
    expect(ConditionLabel.values.map((label) => label.code).toSet(), {
      'bacterial_leaf_blight', 'blast', 'brown_spot', 'tungro', 'healthy',
    });
    expect(
      ConditionLabel.values.map((label) => details.getDetail(label).name),
      ['Hawar daun bakteri', 'Blast', 'Bercak coklat', 'Tungro', 'Sehat'],
    );
    for (final label in ConditionLabel.values) {
      final detail = details.getDetail(label);
      expect(detail.needsReview, isTrue);
      expect(detail.symptoms, isNotNull);
      expect(detail.symptoms, isNotEmpty);
      expect(detail.cause, isNotNull);
      expect(detail.cause, isNotEmpty);
      expect(detail.management, isNotNull);
      expect(detail.management, isNotEmpty);
      expect(detail.management, contains('Pemupukan:'));
      expect(detail.management, contains('uji tanah'));
    }
  });

  for (final confidence in [0.74, 0.75]) {
    testWidgets('peringatan hasil untuk confidence $confidence', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScanResultPage(
            photo: _photo,
            prediction: ScanPrediction(
              label: ConditionLabel.healthy,
              confidence: confidence,
              isSimulated: true,
            ),
            detail: details.getDetail(ConditionLabel.healthy),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sehat'), findsOneWidget);
      expect(find.text('Hasil simulasi'), findsOneWidget);
      expect(find.text(warning), confidence < 0.75 ? findsOneWidget : findsNothing);
      await tester.scrollUntilVisible(find.text('Perawatan'), 100);
      expect(find.text('Materi masih perlu ditinjau oleh tim.'), findsOneWidget);
      expect(find.text('Penanganan'), findsNothing);
    });
  }

  testWidgets('galeri, batal, ganti foto, dan hasil simulasi', (tester) async {
    final replacement = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNIaTIDAAJqAR0H9cpaAAAAAElFTkSuQmCC',
    );
    final selections = <Uint8List?>[_photo, null, replacement, null];
    final history = _History();
    final bloc = ScanBloc(
      _Photos((_) async => selections.removeAt(0)),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      history,
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc, history: history, confidencePercent: 90);

    expect(_analyzeButton(tester).onPressed, isNull);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);

    await tester.tap(find.text('Ganti Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(_photo));

    await tester.tap(find.text('Ganti Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(replacement));

    await tester.ensureVisible(find.text('Analisis'));
    await tester.tap(find.text('Analisis'));
    bloc.add(const AnalyzePhoto());
    await tester.pump();
    expect(find.text('Menganalisis…'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Hasil simulasi'), findsOneWidget);
    expect(history.entries, hasLength(1));
    expect(find.text('Bercak coklat'), findsOneWidget);
    expect(find.text('Tingkat keyakinan: 85%'), findsOneWidget);
    expect(find.text(warning), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Penanganan'), 100);
    expect(find.text('Gejala'), findsOneWidget);
    expect(find.text('Penyebab'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kembali ke Scan'), 100);
    await tester.tap(find.text('Kembali ke Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(replacement));
    expect(find.text('Hasil simulasi'), findsNothing);

    await tester.tap(find.byTooltip('Riwayat Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua kondisi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sehat').last);
    await tester.pumpAndSettle();
    expect(find.text('Belum ada scan untuk kondisi ini.'), findsOneWidget);

    await tester.tap(find.text('Sehat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semua kondisi').last);
    await tester.pumpAndSettle();
    expect(find.text('Bercak coklat'), findsOneWidget);
    await tester.tap(find.text('Bercak coklat'));
    await tester.pumpAndSettle();
    expect(find.text('Salinan foto tidak tersedia.'), findsOneWidget);
    expect(find.text('Tingkat keyakinan: 85%'), findsOneWidget);
    expect(find.text(warning), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hapus catatan'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus catatan scan?'), findsOneWidget);
    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(history.entries, hasLength(1));
    await tester.tap(find.byTooltip('Hapus catatan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada riwayat scan.'), findsOneWidget);
  });

  testWidgets('foto dari kamera dalam aplikasi masuk ke pratinjau', (
    tester,
  ) async {
    final bloc = ScanBloc(
      _Photos((_) async => null),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      _History(),
    );
    addTearDown(bloc.close);
    await _openScan(
      tester,
      bloc,
      cameraPage: (context) => Scaffold(
        appBar: AppBar(title: const Text('Kamera dalam aplikasi')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop<Uint8List>(_photo),
            child: const Text('Jepret'),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Ambil Foto'));
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Kamera dalam aplikasi'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(bloc.state.photo, isNull);

    await tester.ensureVisible(find.text('Ambil Foto'));
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Jepret'));
    await tester.pumpAndSettle();

    expect(bloc.state.photo, same(_photo));
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('foto yang ditolak tidak diprediksi atau disimpan', (tester) async {
    final history = _History();
    final prediction = _PendingPrediction();
    final bloc = ScanBloc(
      _Photos((_) async => _photo),
      ScanPhoto(prediction, const _AllowPhoto(allowed: false)),
      history,
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc, history: history);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Analisis'));
    await tester.tap(find.text('Analisis'));
    await tester.pumpAndSettle();

    expect(
      find.text('Foto belum bisa dianalisis. Pilih foto daun padi yang terlihat jelas.'),
      findsOneWidget,
    );
    expect(find.text('Ganti Foto'), findsOneWidget);
    expect(prediction.calls, 0);
    expect(history.entries, isEmpty);
  });

  testWidgets('hasil tetap tampil jika riwayat gagal tersimpan', (tester) async {
    final bloc = ScanBloc(
      _Photos((_) async => _photo),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      _History(failSave: true),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Analisis'));
    await tester.tap(find.text('Analisis'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(
      find.text('Hasil analisis tersedia, tetapi gagal disimpan ke riwayat.'),
      findsOneWidget,
    );
    expect(find.text('Bercak coklat'), findsOneWidget);
  });

  testWidgets('pesan foto gagal dibaca dan foto sebelumnya dipertahankan', (
    tester,
  ) async {
    var calls = 0;
    final bloc = ScanBloc(
      _Photos((_) async {
        if (calls++ == 0) return _photo;
        throw const FormatException('Invalid image');
      }),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      _History(),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);

    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti Foto'));
    await tester.pumpAndSettle();

    expect(find.text('Foto tidak dapat dibaca. Coba pilih foto lain.'), findsOneWidget);
    expect(bloc.state.photo, same(_photo));
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('kamera batal atau gagal, lalu bisa memilih foto', (tester) async {
    var cameraCalls = 0;
    final bloc = ScanBloc(
      _Photos((source) async {
        if (source == PhotoSource.gallery) return _photo;
        switch (cameraCalls++) {
          case 0:
            return null;
          case 1:
            throw Exception('Camera unavailable');
          default:
            return Uint8List.fromList(_photo);
        }
      }),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      _History(),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(_photo));

    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect(
      find.text('Kamera gagal mengambil foto. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(bloc.state.photo, same(_photo));

    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.status, ScanStatus.ready);
    expect(bloc.state.photo, isNot(same(_photo)));
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('foto dari picker Android dipulihkan ke pratinjau', (tester) async {
    final recovered = Completer<Uint8List?>();
    final bloc = ScanBloc(
      _Photos((_) async => null, recover: () => recovered.future),
      ScanPhoto(SimulatedPredictionRepository(), const _AllowPhoto()),
      _History(),
    )..add(const RecoverPickerPhoto());
    addTearDown(bloc.close);
    await _openScan(tester, bloc);
    await tester.pump();

    expect(bloc.state.status, ScanStatus.recovering);
    expect(_analyzeButton(tester).onPressed, isNull);

    recovered.complete(_photo);
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(_photo));
    expect(find.byType(Image), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });

  testWidgets('analisis ganda diabaikan dan kegagalan bisa dicoba lagi', (
    tester,
  ) async {
    final prediction = _PendingPrediction();
    final bloc = ScanBloc(
      _Photos((_) async => _photo),
      ScanPhoto(prediction, const _AllowPhoto()),
      _History(),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();

    final scanLine = find.byKey(const Key('scan-line'));
    expect(scanLine, findsNothing);
    bloc.add(const AnalyzePhoto());
    bloc.add(const AnalyzePhoto());
    await tester.pump();
    await tester.pump();

    expect(scanLine, findsOneWidget);
    final initialPosition = tester.getCenter(scanLine).dy;
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.getCenter(scanLine).dy, greaterThan(initialPosition));
    expect(prediction.calls, 1);
    expect(_analyzeButton(tester).onPressed, isNull);
    prediction.result.completeError(Exception('Prediction failed'));
    await tester.pumpAndSettle();

    expect(scanLine, findsNothing);
    expect(find.text('Analisis gagal. Silakan coba lagi.'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });
}

Future<void> _openScan(
  WidgetTester tester,
  ScanBloc bloc, {
  HistoryRepository? history,
  WidgetBuilder? cameraPage,
  int confidencePercent = AppSettings.defaultConfidencePercent,
}) => tester.pumpWidget(
  MaterialApp(
    home: BlocProvider.value(
      value: bloc,
      child: ScanPage(
        details: const LocalDiseaseDetailRepository(),
        history: history ?? _History(),
        cameraPage: cameraPage,
        confidencePercent: confidencePercent,
      ),
    ),
  ),
);

FilledButton _analyzeButton(WidgetTester tester) =>
    tester.allWidgets.whereType<FilledButton>().single;

class _Photos implements PhotoRepository {
  const _Photos(this.pick, {this.recover});

  final Future<Uint8List?> Function(PhotoSource) pick;
  final Future<Uint8List?> Function()? recover;

  @override
  Future<Uint8List?> pickPhoto(PhotoSource source) => pick(source);

  @override
  Future<Uint8List?> recoverPhoto() async => await recover?.call();
}

class _PendingPrediction implements PredictionRepository {
  final result = Completer<ScanPrediction>();
  int calls = 0;

  @override
  Future<ScanPrediction> predict(Uint8List photo) {
    calls++;
    return result.future;
  }
}

class _History implements HistoryRepository {
  _History({this.failSave = false});

  final bool failSave;
  final entries = <HistoryEntry>[];

  @override
  Future<void> save({
    required ConditionLabel label,
    required double confidence,
    required DateTime scannedAt,
    required bool isSimulated,
    required Uint8List photo,
  }) async {
    if (failSave) throw Exception('Storage unavailable');
    entries.add(HistoryEntry(
      id: entries.length + 1,
      label: label,
      confidence: confidence,
      scannedAt: scannedAt,
      isSimulated: isSimulated,
    ));
  }

  @override
  Future<List<HistoryEntry>> list({ConditionLabel? label}) async =>
      entries.where((entry) => label == null || label == entry.label).toList();

  @override
  Future<void> delete(int id) async {
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<Uint8List?> readPhoto(int id) async => null;
}


class _DefaultSettings implements SettingsRepository {
  @override
  Future<AppSettings> load() async => const AppSettings();

  @override
  Future<void> save(AppSettings settings) async {}
}

class _AllowPhoto implements RicePhotoScreening {
  const _AllowPhoto({this.allowed = true});

  final bool allowed;

  @override
  Future<bool> accepts(Uint8List photo) async => allowed;
}
