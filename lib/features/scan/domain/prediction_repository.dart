import 'dart:typed_data';

import '../../knowledge/domain/condition_label.dart';

class ScanPrediction {
  const ScanPrediction({
    required this.label,
    required this.confidence,
    required this.isSimulated,
  });

  final ConditionLabel label;
  final double confidence;
  final bool isSimulated;
}

abstract interface class PredictionRepository {
  /// Returns an on-device prediction with confidence between 0 and 1.
  /// Implementations surface model and preprocessing errors by throwing.
  Future<ScanPrediction> predict(Uint8List photo);
}
