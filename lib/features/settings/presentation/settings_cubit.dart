import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/settings_repository.dart';

class SettingsState {
  const SettingsState({
    this.settings = const AppSettings(),
    this.loaded = false,
    this.busy = false,
    this.error,
  });

  final AppSettings settings;
  final bool loaded;
  final bool busy;
  final String? error;

  bool get canEdit => loaded && !busy;
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._repository) : super(const SettingsState());

  final SettingsRepository _repository;

  Future<void> load() async {
    if (state.busy || state.loaded || isClosed) return;
    emit(const SettingsState(busy: true));
    try {
      final settings = await _repository.load();
      if (!isClosed) emit(SettingsState(settings: settings, loaded: true));
    } catch (_) {
      if (!isClosed) {
        emit(const SettingsState(error: 'Pengaturan gagal dimuat.'));
      }
    }
  }

  Future<void> setConfidencePercent(int value) async {
    final current = state.settings;
    if (value == current.confidencePercent || value < 0 || value > 100) {
      return;
    }
    await _save(AppSettings(confidencePercent: value, theme: current.theme));
  }

  Future<void> setTheme(AppThemePreference value) async {
    final current = state.settings;
    if (value == current.theme) return;
    await _save(AppSettings(
      confidencePercent: current.confidencePercent,
      theme: value,
    ));
  }

  Future<void> _save(AppSettings settings) async {
    if (!state.canEdit || isClosed) return;
    final previous = state.settings;
    emit(SettingsState(settings: previous, loaded: true, busy: true));
    try {
      await _repository.save(settings);
      if (!isClosed) emit(SettingsState(settings: settings, loaded: true));
    } catch (_) {
      if (!isClosed) {
        emit(SettingsState(
          settings: previous,
          loaded: true,
          error: 'Pengaturan gagal disimpan. Silakan coba lagi.',
        ));
      }
    }
  }
}
