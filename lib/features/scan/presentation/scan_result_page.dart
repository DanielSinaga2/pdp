import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../domain/prediction_repository.dart';

class ScanResultPage extends StatelessWidget {
  const ScanResultPage({
    super.key,
    required this.photo,
    required this.prediction,
  });

  final Uint8List photo;
  final ScanPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = (prediction.confidence * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Hasil analisis')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              children: [
                ScanPhotoPreview(photo: photo),
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
                          prediction.condition,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text('Tingkat keyakinan: $confidence%'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kembali ke Scan'),
                ),
              ],
            ),
          ),
        ),
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
