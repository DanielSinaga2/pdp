import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/scan/data/simulated_prediction_repository.dart';
import 'package:pdp/features/scan/domain/photo_repository.dart';
import 'package:pdp/features/scan/domain/prediction_repository.dart';
import 'package:pdp/features/scan/domain/scan_photo.dart';
import 'package:pdp/features/scan/presentation/scan_bloc.dart';
import 'package:pdp/features/scan/presentation/scan_page.dart';

final _photo = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGMwK3YGAAHPAO2uH13mAAAAAElFTkSuQmCC',
);

void main() {
  testWidgets('galeri, batal, ganti foto, dan hasil simulasi', (tester) async {
    final replacement = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAIAAACQd1PeAAAADElEQVR4nGNIaTIDAAJqAR0H9cpaAAAAAElFTkSuQmCC',
    );
    final selections = <Uint8List?>[_photo, null, replacement, null];
    final bloc = ScanBloc(
      _Photos((_) async => selections.removeAt(0)),
      ScanPhoto(SimulatedPredictionRepository()),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);

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

    await tester.tap(find.text('Analisis'));
    await tester.pump();
    expect(find.text('Menganalisis…'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNull);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(find.text('Hasil simulasi'), findsOneWidget);
    expect(find.text('Bercak coklat'), findsOneWidget);
    expect(find.text('Tingkat keyakinan: 85%'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    await tester.tap(find.text('Kembali ke Scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ganti Foto'));
    await tester.pumpAndSettle();
    expect(bloc.state.photo, same(replacement));
    expect(find.text('Hasil simulasi'), findsNothing);
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
      ScanPhoto(SimulatedPredictionRepository()),
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
      ScanPhoto(SimulatedPredictionRepository()),
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
      ScanPhoto(SimulatedPredictionRepository()),
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
      ScanPhoto(prediction),
    );
    addTearDown(bloc.close);
    await _openScan(tester, bloc);
    await tester.tap(find.text('Pilih Foto dari Galeri'));
    await tester.pumpAndSettle();

    bloc.add(const AnalyzePhoto());
    bloc.add(const AnalyzePhoto());
    await tester.pump();

    expect(prediction.calls, 1);
    expect(_analyzeButton(tester).onPressed, isNull);
    prediction.result.completeError(Exception('Prediction failed'));
    await tester.pumpAndSettle();

    expect(find.text('Analisis gagal. Silakan coba lagi.'), findsOneWidget);
    expect(_analyzeButton(tester).onPressed, isNotNull);
  });
}

Future<void> _openScan(WidgetTester tester, ScanBloc bloc) => tester.pumpWidget(
  MaterialApp(home: BlocProvider.value(value: bloc, child: const ScanPage())),
);

FilledButton _analyzeButton(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton));

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
