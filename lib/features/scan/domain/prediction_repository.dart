import 'dart:typed_data';

class ScanPrediction {
  const ScanPrediction({required this.condition, required this.confidence});

  final String condition;
  final double confidence;
}

abstract interface class PredictionRepository {
  Future<ScanPrediction> predict(Uint8List photo);
}
