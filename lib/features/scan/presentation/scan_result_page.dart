import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../knowledge/domain/condition_label.dart';
import '../../knowledge/domain/disease_detail_repository.dart';
import '../domain/prediction_repository.dart';

const _confidenceThreshold = 0.75;

class ScanResultPage extends StatelessWidget {
  const ScanResultPage({
    super.key,
    required this.photo,
    required this.prediction,
    required this.detail,
    this.historySaveFailed = false,
    this.scannedAtLabel,
  });

  final Uint8List? photo;
  final ScanPrediction prediction;
  final DiseaseDetail detail;
  final bool historySaveFailed;
  final String? scannedAtLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowConfidence = prediction.confidence < _confidenceThreshold;
    final roundedPercent = (prediction.confidence * 100).toStringAsFixed(1);
    final confidence = lowConfidence && roundedPercent == '75.0'
        ? '<75%'
        : '${roundedPercent.replaceFirst(RegExp(r'\.0$'), '').replaceFirst('.', ',')}%';

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil analisis')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                if (photo case final image?)
                  ScanPhotoPreview(photo: image)
                else
                  const Text('Salinan foto tidak tersedia.'),
                if (historySaveFailed)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Hasil analisis tersedia, tetapi gagal disimpan ke riwayat.',
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (prediction.isSimulated) ...[
                          const Chip(label: Text('Hasil simulasi')),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          detail.name,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Tingkat keyakinan: $confidence'),
                        if (scannedAtLabel case final timestamp?) Text(timestamp),
                        if (lowConfidence) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Hasil kurang meyakinkan. Coba ambil foto ulang '
                            'dengan pencahayaan yang lebih baik.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (detail.needsReview)
                  Text(
                    'Materi masih perlu ditinjau oleh tim.',
                    style: theme.textTheme.labelLarge,
                  ),
                _DetailSection(title: 'Gejala', content: detail.symptoms),
                _DetailSection(title: 'Penyebab', content: detail.cause),
                _DetailSection(
                  title: prediction.label == ConditionLabel.healthy
                      ? 'Perawatan'
                      : 'Penanganan',
                  content: detail.management,
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    scannedAtLabel == null ? 'Kembali ke Scan' : 'Kembali ke Riwayat',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.content});

  final String title;
  final String? content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(content ?? 'Materi belum tersedia.'),
        ],
      ),
    );
  }
}

class ScanPhotoPreview extends StatelessWidget {
  const ScanPhotoPreview({super.key, required this.photo});

  final Uint8List photo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Image.memory(
          photo,
          height: 240,
          width: double.infinity,
          fit: BoxFit.contain,
          semanticLabel: 'Foto daun padi yang dipilih',
          errorBuilder: (_, _, _) =>
              const Center(child: Text('Foto tidak dapat dibaca.')),
        ),
      ),
    );
  }
}
