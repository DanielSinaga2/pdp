import 'dart:typed_data';

import 'prediction_repository.dart';
import 'rice_photo_screening.dart';

class ScanPhoto {
  const ScanPhoto(this._repository, this._screening);

  final PredictionRepository _repository;
  final RicePhotoScreening _screening;

  Future<ScanPrediction> call(Uint8List photo) async {
    if (!await _screening.accepts(photo)) {
      throw const UnsuitableRicePhoto();
    }
    return _repository.predict(photo);
  }
}
