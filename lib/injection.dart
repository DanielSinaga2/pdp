import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/history/data/drift_history_repository.dart';
import 'features/history/data/history_database.dart';
import 'features/history/domain/history_repository.dart';
import 'features/knowledge/data/local_disease_detail_repository.dart';
import 'features/knowledge/domain/disease_detail_repository.dart';
import 'features/scan/data/image_picker_photo_repository.dart';
import 'features/scan/data/simulated_prediction_repository.dart';
import 'features/scan/data/tflite_platform.dart';
import 'features/scan/data/tflite_prediction_repository.dart';
import 'features/scan/data/vegetation_color_screening.dart';
import 'features/scan/domain/photo_repository.dart';
import 'features/scan/domain/prediction_repository.dart';
import 'features/scan/domain/rice_photo_screening.dart';
import 'features/scan/domain/scan_photo.dart';
import 'features/scan/presentation/scan_bloc.dart';
import 'features/settings/data/local_settings_repository.dart';
import 'features/settings/domain/settings_repository.dart';
import 'features/settings/presentation/settings_cubit.dart';

final getIt = GetIt.instance;

/// Jalankan dengan `--dart-define=SIMULATED_MODEL=true` untuk memakai hasil
/// simulasi (mis. saat berkas model belum ada di assets/model/).
const _useSimulatedModel = bool.fromEnvironment('SIMULATED_MODEL');

void configureDependencies() {
  getIt.registerLazySingleton<SettingsRepository>(
    () => LocalSettingsRepository(SharedPreferencesAsync()),
  );
  getIt.registerFactory(
    () => SettingsCubit(getIt<SettingsRepository>())..load(),
  );
  getIt.registerLazySingleton<HistoryDatabase>(
    () => HistoryDatabase(LazyDatabase(() async {
      final support = await getApplicationSupportDirectory();
      await support.create(recursive: true);
      return NativeDatabase.createInBackground(
        File(p.join(support.path, 'scan_history.sqlite')),
      );
    })),
    dispose: (database) => database.close(),
  );
  getIt.registerLazySingleton<HistoryRepository>(
    () => DriftHistoryRepository(getIt<HistoryDatabase>(), () async {
      final support = await getApplicationSupportDirectory();
      return Directory(p.join(support.path, 'scan_history_photos'));
    }),
  );
  getIt.registerSingleton<DiseaseDetailRepository>(
    const LocalDiseaseDetailRepository(),
  );
  getIt.registerLazySingleton<PhotoRepository>(
    () => ImagePickerPhotoRepository(ImagePicker()),
  );
  getIt.registerLazySingleton<PredictionRepository>(
    () => _useSimulatedModel
        ? SimulatedPredictionRepository()
        : createTflitePredictionRepository(),
    dispose: (repository) {
      if (repository is TflitePredictionRepository) repository.dispose();
    },
  );
  getIt.registerSingleton<RicePhotoScreening>(
    const VegetationColorScreening(UiPhotoPreprocessor()),
  );
  getIt.registerLazySingleton(
    () => ScanPhoto(getIt<PredictionRepository>(), getIt<RicePhotoScreening>()),
  );
  getIt.registerFactory(
    () => ScanBloc(
      getIt<PhotoRepository>(),
      getIt<ScanPhoto>(),
      getIt<HistoryRepository>(),
    )
      ..add(const RecoverPickerPhoto()),
  );
}
