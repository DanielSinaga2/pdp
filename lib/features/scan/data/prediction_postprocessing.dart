import 'dart:math' as math;

import '../../knowledge/domain/condition_label.dart';
import '../domain/prediction_repository.dart';

/// Pemetaan nama kelas pada model -> [ConditionLabel] milik aplikasi.
///
/// Model Paddy Doctor memiliki 10 kelas; hanya yang tercantum di sini yang
/// dikenal aplikasi. Kelas lain (mis. `hispa`, `dead_heart`) dianggap di luar
/// cakupan: probabilitasnya tidak dihitung ke label mana pun sehingga
/// keyakinan label yang dipilih ikut turun, dan halaman hasil menampilkan
/// peringatan "kurang meyakinkan" bila di bawah ambang pengaturan.
const Map<String, ConditionLabel> kModelClassToLabel = {
  'bacterial_leaf_blight': ConditionLabel.bacterialLeafBlight,
  'blast': ConditionLabel.blast,
  'brown_spot': ConditionLabel.brownSpot,
  'tungro': ConditionLabel.tungro,
  'normal': ConditionLabel.healthy,
  'healthy': ConditionLabel.healthy,
};

/// Mengubah keluaran model menjadi distribusi probabilitas.
///
/// Model dari notebook berakhir dengan softmax sehingga biasanya tidak diubah.
/// Jika nilainya di luar [0, 1] atau jumlahnya jauh dari 1 (mis. logit),
/// softmax yang stabil secara numerik diterapkan.
List<double> toProbabilities(List<double> raw) {
  if (raw.isEmpty) throw const FormatException('Keluaran model kosong.');
  if (raw.any((value) => !value.isFinite)) {
    throw const FormatException('Keluaran model mengandung nilai tidak valid.');
  }

  final sum = raw.fold<double>(0, (total, value) => total + value);
  final inRange = raw.every((value) => value >= 0 && value <= 1);
  if (inRange && (sum - 1).abs() <= 0.01) return List<double>.of(raw);

  final peak = raw.reduce(math.max);
  final exps = [for (final value in raw) math.exp(value - peak)];
  final total = exps.fold<double>(0, (acc, value) => acc + value);
  return [for (final value in exps) value / total];
}

/// Memilih label aplikasi dengan probabilitas tertinggi.
///
/// Probabilitas kelas yang dipetakan ke label yang sama dijumlahkan.
/// Keyakinan yang dikembalikan adalah probabilitas MENTAH label terpilih
/// (tidak dinormalisasi ulang terhadap kelas yang dikenal aplikasi).
ScanPrediction pickPrediction(
  List<String> classes,
  List<double> probabilities,
) {
  if (classes.length != probabilities.length) {
    throw FormatException(
      'Jumlah kelas (${classes.length}) tidak sama dengan keluaran model '
      '(${probabilities.length}).',
    );
  }

  final perLabel = <ConditionLabel, double>{};
  for (var i = 0; i < classes.length; i++) {
    final label = kModelClassToLabel[classes[i]];
    if (label == null) continue;
    perLabel[label] = (perLabel[label] ?? 0) + probabilities[i];
  }
  if (perLabel.isEmpty) {
    throw FormatException(
      'Tidak ada kelas model yang dikenal aplikasi: ${classes.join(', ')}.',
    );
  }

  final best = perLabel.entries.reduce((a, b) => b.value > a.value ? b : a);
  return ScanPrediction(
    label: best.key,
    confidence: best.value.clamp(0.0, 1.0).toDouble(),
    isSimulated: false,
  );
}
