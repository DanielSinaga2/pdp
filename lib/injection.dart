import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import 'features/scan/data/image_picker_gallery_repository.dart';
import 'features/scan/data/simulated_prediction_repository.dart';
import 'features/scan/domain/gallery_repository.dart';
import 'features/scan/domain/prediction_repository.dart';
import 'features/scan/domain/scan_photo.dart';
import 'features/scan/presentation/scan_bloc.dart';

final getIt = GetIt.instance;

void configureDependencies() {
  getIt.registerLazySingleton<GalleryRepository>(
    () => ImagePickerGalleryRepository(ImagePicker()),
  );
  getIt.registerLazySingleton<PredictionRepository>(
    SimulatedPredictionRepository.new,
  );
  getIt.registerLazySingleton(() => ScanPhoto(getIt<PredictionRepository>()));
  getIt.registerFactory(
    () => ScanBloc(getIt<GalleryRepository>(), getIt<ScanPhoto>()),
  );
}
