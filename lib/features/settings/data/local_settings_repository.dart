import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/settings_repository.dart';

class LocalSettingsRepository implements SettingsRepository {
  LocalSettingsRepository(this._preferences);

  final SharedPreferencesAsync _preferences;
  static const _key = 'padisehat.settings.v1';

  @override
  Future<AppSettings> load() async {
    final stored = await _preferences.getString(_key);
    if (stored == null) return const AppSettings();

    final data = jsonDecode(stored);
    if (data is! Map<String, dynamic>) return const AppSettings();

    final percent = data['confidencePercent'];
    final theme = AppThemePreference.values.firstWhere(
      (value) => value.name == data['theme'],
      orElse: () => AppThemePreference.system,
    );
    return AppSettings(
      confidencePercent: percent is int && percent >= 0 && percent <= 100
          ? percent
          : AppSettings.defaultConfidencePercent,
      theme: theme,
    );
  }

  @override
  Future<void> save(AppSettings settings) => _preferences.setString(
    _key,
    jsonEncode({
      'confidencePercent': settings.confidencePercent,
      'theme': settings.theme.name,
    }),
  );
}
