enum AppThemePreference { system, light, dark }

class AppSettings {
  const AppSettings({
    this.confidencePercent = defaultConfidencePercent,
    this.theme = AppThemePreference.system,
  }) : assert(confidencePercent >= 0 && confidencePercent <= 100);

  static const defaultConfidencePercent = 75;

  final int confidencePercent;
  final AppThemePreference theme;
}

abstract interface class SettingsRepository {
  Future<AppSettings> load();

  Future<void> save(AppSettings settings);
}
