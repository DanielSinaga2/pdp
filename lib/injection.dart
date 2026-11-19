import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'features/knowledge/data/local_disease_detail_repository.dart';
import 'features/knowledge/domain/disease_detail_repository.dart';
import 'features/scan/data/image_picker_photo_repository.dart';
import 'features/scan/data/simulated_prediction_repository.dart';
import 'features/scan/domain/photo_repository.dart';
import 'features/scan/domain/prediction_repository.dart';
import 'features/scan/domain/scan_photo.dart';
import 'features/scan/presentation/scan_bloc.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerSingleton<DiseaseDetailRepository>(
    const LocalDiseaseDetailRepository(),
  );
  getIt.registerLazySingleton<PhotoRepository>(
    () => ImagePickerPhotoRepository(ImagePicker()),
  );
  getIt.registerLazySingleton<PredictionRepository>(
    SimulatedPredictionRepository.new,
  );
  getIt.registerLazySingleton(() => ScanPhoto(getIt<PredictionRepository>()));
  getIt.registerFactory(
    () => ScanBloc(getIt<PhotoRepository>(), getIt<ScanPhoto>())
      ..add(const RecoverPickerPhoto()),
  );
}
