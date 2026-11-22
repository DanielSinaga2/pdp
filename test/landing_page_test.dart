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
    expect(find.textContaining('Deteksi Penyakit Padi'), findsOneWidget);
    expect(find.text('Mulai Scan'), findsOneWidget);

    await tester.tap(find.text('Mulai Scan'));
    expect(started, isTrue);
  });
}
