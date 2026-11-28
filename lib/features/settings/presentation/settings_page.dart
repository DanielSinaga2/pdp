import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../domain/settings_repository.dart';
import '../../../presentation/padi_style.dart';
import '../../scan/presentation/app_navigation.dart';
import 'settings_cubit.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int? _draftPercent;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        final cubit = context.read<SettingsCubit>();
        final theme = Theme.of(context);
        final percent = _draftPercent ?? state.settings.confidencePercent;

        return Scaffold(
          bottomNavigationBar: const AppNavigation(
            current: AppDestination.settings,
          ),
          appBar: AppBar(title: const Text('Pengaturan')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    if (state.busy) const LinearProgressIndicator(),
                    if (state.error case final error?) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          error,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                      if (!state.loaded)
                        TextButton(
                          onPressed: cubit.load,
                          child: const Text('Coba lagi'),
                        ),
                      const SizedBox(height: 16),
                    ],
                    GlassSurface(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambang tingkat keyakinan',
                            style: theme.textTheme.titleLarge,
                          ),
                          Text(
                            '$percent%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Slider(
                            value: percent.toDouble(),
                            max: 100,
                            divisions: 100,
                            label: '$percent%',
                            semanticFormatterCallback: (value) =>
                                '${value.round()}%',
                            onChanged: state.canEdit
                                ? (value) => setState(
                                    () => _draftPercent = value.round(),
                                  )
                                : null,
                            onChangeEnd: state.canEdit
                                ? (value) {
                                    setState(() => _draftPercent = null);
                                    cubit.setConfidencePercent(value.round());
                                  }
                                : null,
                          ),
                          const Text(
                            'Hasil di bawah ambang ini menampilkan saran '
                            'untuk mengambil foto ulang.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tema'),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<AppThemePreference>(
                          isExpanded: true,
                          value: state.settings.theme,
                          items: const [
                            DropdownMenuItem(
                              value: AppThemePreference.system,
                              child: Text('Sistem'),
                            ),
                            DropdownMenuItem(
                              value: AppThemePreference.light,
                              child: Text('Terang'),
                            ),
                            DropdownMenuItem(
                              value: AppThemePreference.dark,
                              child: Text('Gelap'),
                            ),
                          ],
                          onChanged: state.canEdit
                              ? (value) {
                                  if (value != null) cubit.setTheme(value);
                                }
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
