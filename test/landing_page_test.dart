import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/scan/presentation/landing_page.dart';

void main() {
  testWidgets('menu beranda dapat digunakan di layar kecil bertema gelap', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const LandingPage(),
        routes: {
          LandingPage.scanRoute: (_) =>
              const Scaffold(body: Text('Tujuan menu Scan')),
        },
      ),
    );

    expect(find.byKey(const Key('padisehat-logo')), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Scan'), 100);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    await tester.tap(find.text('Scan'));
    await tester.pumpAndSettle();
    expect(find.text('Tujuan menu Scan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
