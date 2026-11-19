import 'dart:typed_data';

import '../../knowledge/domain/condition_label.dart';
import '../domain/prediction_repository.dart';

class SimulatedPredictionRepository implements PredictionRepository {
  @override
  Future<ScanPrediction> predict(Uint8List photo) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return const ScanPrediction(
      label: ConditionLabel.brownSpot,
      confidence: 0.85,
      isSimulated: true,
    );
  }
}
