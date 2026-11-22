import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'features/history/domain/history_repository.dart';
import 'features/knowledge/domain/disease_detail_repository.dart';
import 'features/scan/presentation/landing_page.dart';
import 'features/scan/presentation/scan_bloc.dart';
import 'features/scan/presentation/scan_page.dart';
import 'features/settings/domain/settings_repository.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'injection.dart';

void main() {
  configureDependencies();
  runApp(const PadiSehatApp());
}

class PadiSehatApp extends StatelessWidget {
  const PadiSehatApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF367343);

    return BlocProvider(
      create: (_) => getIt<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final settings = state.settings;
          return MaterialApp(
            title: 'PadiSehat',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: seed),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seed,
                brightness: Brightness.dark,
              ),
            ),
            themeMode: switch (settings.theme) {
              AppThemePreference.system => ThemeMode.system,
              AppThemePreference.light => ThemeMode.light,
              AppThemePreference.dark => ThemeMode.dark,
            },
            home: BlocProvider(
              lazy: false,
              create: (_) => getIt<ScanBloc>(),
              child: Builder(
                builder: (context) => LandingPage(
                  onStart: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<ScanBloc>(),
                        child: BlocSelector<SettingsCubit, SettingsState, int>(
                          selector: (state) => state.settings.confidencePercent,
                          builder: (context, confidencePercent) => ScanPage(
                            details: getIt<DiseaseDetailRepository>(),
                            history: getIt<HistoryRepository>(),
                            confidencePercent: confidencePercent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
