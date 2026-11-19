import 'dart:typed_data';

import 'prediction_repository.dart';

class ScanPhoto {
  const ScanPhoto(this._repository);

  final PredictionRepository _repository;

  Future<ScanPrediction> call(Uint8List photo) => _repository.predict(photo);
}
