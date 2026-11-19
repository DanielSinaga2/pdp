import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdp/features/settings/domain/settings_repository.dart';
import 'package:pdp/features/settings/presentation/settings_cubit.dart';
import 'package:pdp/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('tema dan ambang dipulihkan saat SettingsCubit dibuat ulang', (
    tester,
  ) async {
    final repository = _SettingsStore();
    final cubit = SettingsCubit(repository);
    await cubit.load();
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: const MaterialApp(home: SettingsPage()),
      ),
    );

    expect(find.text('75%'), findsOneWidget);
    final slider = tester.widget<Slider>(find.byType(Slider));
    slider.onChanged!(90);
    slider.onChangeEnd!(90);
    await tester.pumpAndSettle();
    expect(find.text('90%'), findsOneWidget);

    await tester.tap(find.text('Sistem'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap').last);
    await tester.pumpAndSettle();
    expect(cubit.state.settings.theme, AppThemePreference.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();

    final reopened = SettingsCubit(repository);
    addTearDown(reopened.close);
    await reopened.load();
    expect(reopened.state.settings.confidencePercent, 90);
    expect(reopened.state.settings.theme, AppThemePreference.dark);
  });

  test('kegagalan simpan mempertahankan pengaturan terakhir', () async {
    final repository = _SettingsStore();
    final cubit = SettingsCubit(repository);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.setTheme(AppThemePreference.light);

    repository.failSave = true;
    await cubit.setConfidencePercent(95);
    expect(cubit.state.settings.confidencePercent, 75);
    expect(cubit.state.settings.theme, AppThemePreference.light);
    expect(cubit.state.error, 'Pengaturan gagal disimpan. Silakan coba lagi.');
  });
}

class _SettingsStore implements SettingsRepository {
  AppSettings stored = const AppSettings();
  bool failSave = false;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    if (failSave) throw Exception('Storage unavailable');
    stored = settings;
  }
}
