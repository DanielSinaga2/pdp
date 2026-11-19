import 'dart:typed_data';

import '../../knowledge/domain/condition_label.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.label,
    required this.confidence,
    required this.scannedAt,
    required this.isSimulated,
  });

  final int id;
  final ConditionLabel label;
  final double confidence;
  final DateTime scannedAt;
  final bool isSimulated;
}

abstract interface class HistoryRepository {
  Future<void> save({
    required ConditionLabel label,
    required double confidence,
    required DateTime scannedAt,
    required bool isSimulated,
    required Uint8List photo,
  });

  Future<List<HistoryEntry>> list({ConditionLabel? label});

  /// Returns null if the managed photo is missing or cannot be read.
  Future<Uint8List?> readPhoto(int id);

  Future<void> delete(int id);
}
