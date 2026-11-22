import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/scan/presentation/landing_page.dart';

void main() {
  testWidgets('landing page menampilkan pengenalan dan memulai scan', (
    tester,
  ) async {
    var started = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LandingPage(onStart: () => started = true),
      ),
    );

    expect(find.byKey(const Key('padisehat-logo')), findsOneWidget);
    expect(find.text('Deteksi Penyakit Padi'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Analisis daun padi dari kamera atau galeri'), findsOneWidget);

    await tester.ensureVisible(find.text('Scan'));
    await tester.tap(find.text('Scan'));
    expect(started, isTrue);
  });

  testWidgets('kartu Scan dapat dicapai pada layar kecil bertema gelap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var started = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: LandingPage(onStart: () => started = true),
      ),
    );
    await tester.scrollUntilVisible(find.text('Scan'), 100);
    await tester.tap(find.text('Scan'));
    expect(started, isTrue);
    expect(tester.takeException(), isNull);
  });
}
