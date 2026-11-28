import 'package:flutter/foundation.dart' as platform;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'features/history/domain/history_repository.dart';
import 'features/history/presentation/history_cubit.dart';
import 'features/history/presentation/history_page.dart';
import 'features/knowledge/domain/disease_detail_repository.dart';
import 'features/scan/presentation/camera_scan_page.dart';
import 'features/scan/presentation/landing_page.dart';
import 'features/scan/presentation/onboarding_page.dart';
import 'features/scan/presentation/scan_bloc.dart';
import 'features/scan/presentation/scan_page.dart';
import 'features/settings/domain/settings_repository.dart';
import 'features/settings/presentation/settings_cubit.dart';
import 'features/settings/presentation/settings_page.dart';
import 'injection.dart';
import 'presentation/padi_style.dart';

void main() {
  configureDependencies();
  runApp(const PadiSehatApp());
}

class PadiSehatApp extends StatelessWidget {
  const PadiSehatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsCubit>()),
        BlocProvider(lazy: false, create: (_) => getIt<ScanBloc>()),
      ],
      child: BlocSelector<SettingsCubit, SettingsState, AppThemePreference>(
        selector: (state) => state.settings.theme,
        builder: (context, theme) {
          return MaterialApp(
            title: 'PadiSehat',
            theme: padiTheme(Brightness.light),
            darkTheme: padiTheme(Brightness.dark),
            builder: (context, child) =>
                PadiBackdrop(child: child ?? const SizedBox.shrink()),
            themeMode: switch (theme) {
              AppThemePreference.system => ThemeMode.system,
              AppThemePreference.light => ThemeMode.light,
              AppThemePreference.dark => ThemeMode.dark,
            },
            home: const OnboardingPage(),
            routes: {
              LandingPage.homeRoute: (_) => const LandingPage(),
              LandingPage.scanRoute: (_) =>
                  BlocSelector<SettingsCubit, SettingsState, int>(
                    selector: (state) => state.settings.confidencePercent,
                    builder: (_, confidencePercent) => ScanPage(
                      details: getIt<DiseaseDetailRepository>(),
                      history: getIt<HistoryRepository>(),
                      confidencePercent: confidencePercent,
                      cameraPage:
                          !platform.kIsWeb &&
                              platform.defaultTargetPlatform ==
                                  platform.TargetPlatform.android
                          ? (_) => const CameraScanPage()
                          : null,
                    ),
                  ),
              LandingPage.historyRoute: (_) => BlocProvider(
                create: (_) => HistoryCubit(getIt<HistoryRepository>())..load(),
                child: BlocSelector<SettingsCubit, SettingsState, int>(
                  selector: (state) => state.settings.confidencePercent,
                  builder: (_, confidencePercent) => HistoryPage(
                    details: getIt<DiseaseDetailRepository>(),
                    repository: getIt<HistoryRepository>(),
                    confidencePercent: confidencePercent,
                  ),
                ),
              ),
              LandingPage.settingsRoute: (_) => const SettingsPage(),
            },
          );
        },
      ),
    );
  }
}
