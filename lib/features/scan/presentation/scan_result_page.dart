import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../knowledge/domain/condition_label.dart';
import '../../knowledge/domain/disease_detail_repository.dart';
import '../../settings/domain/settings_repository.dart';
import '../domain/disease_analysis.dart';
import '../domain/fuzzy_logic.dart';
import '../domain/prediction_repository.dart';
import 'ai_analysis_detail_page.dart';

class ScanResultPage extends StatelessWidget {
  const ScanResultPage({
    super.key,
    required this.photo,
    required this.prediction,
    required this.detail,
    this.historySaveFailed = false,
    this.confidencePercent = AppSettings.defaultConfidencePercent,
    this.scannedAtLabel,
    this.analysisService,
    this.diseaseDetails,
  });

  final Uint8List? photo;
  final ScanPrediction prediction;
  final DiseaseDetail detail;
  final bool historySaveFailed;
  final int confidencePercent;
  final String? scannedAtLabel;
  final DiseaseAnalysisService? analysisService;
  final DiseaseDetailRepository? diseaseDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service =
        analysisService ?? DiseaseAnalysisService.fromNotebookDraft();
    var currentAnalysis = service.analyze(
      prediction: prediction,
      observations: const [],
      fuzzyInputs: const FuzzyInputs(),
      diseaseDetail: detail,
    );
    final lowConfidence = prediction.confidence < confidencePercent / 100;
    final roundedPercent = (prediction.confidence * 100).toStringAsFixed(1);
    final confidence = lowConfidence && roundedPercent == '$confidencePercent.0'
        ? '<$confidencePercent%'
        : '${roundedPercent.replaceFirst(RegExp(r'\.0$'), '').replaceFirst('.', ',')}%';

    return StatefulBuilder(
      builder: (context, setState) {
        final analysis = currentAnalysis;
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
                            const SizedBox(height: 12),
                            _AnalysisStatusLine(
                              title: 'Certainty Factor',
                              value: analysis.certaintyResult.score == null
                                  ? 'Belum dihitung'
                                  : analysis.certaintyResult.score!
                                        .toStringAsFixed(3),
                            ),
                            _AnalysisStatusLine(
                              title: 'Input keparahan',
                              value: analysis.severityInputPercent == null
                                  ? 'Belum diisi'
                                  : '${analysis.severityInputPercent!.toStringAsFixed(0)}%',
                            ),
                            _AnalysisStatusLine(
                              title: 'Skor Sugeno',
                              value:
                                  analysis.fuzzyResult.chemicalScore
                                      ?.toStringAsFixed(2) ??
                                  'Belum dihitung',
                            ),
                            _AnalysisStatusLine(
                              title: 'Tindak lanjut',
                              value: switch (analysis.chemicalActionLevel) {
                                ChemicalActionLevel.notNeeded =>
                                  'Tidak diperlukan menurut aturan notebook',
                                ChemicalActionLevel.monitor =>
                                  'Siaga / pantau menurut aturan notebook',
                                ChemicalActionLevel.recommended =>
                                  'Disarankan menurut aturan notebook',
                                null => 'Belum dihitung',
                              },
                            ),
                            if (analysis.conflictsWithPrediction)
                              Text(
                                'CF mengarah ke ${analysis.diagnosisCandidate?.code}, '
                                'berbeda dari hasil CNN. Verifikasi diperlukan.',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            if (scannedAtLabel case final timestamp?)
                              Text(timestamp),
                            if (lowConfidence) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Hasil kurang meyakinkan. Coba ambil foto ulang '
                                'dengan pencahayaan yang lebih baik.',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
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
                      content: _managementSummary(detail.management),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFFEAF5DF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () async {
                          final updated = await Navigator.of(context)
                              .push<DiseaseAnalysisResult>(
                                MaterialPageRoute<DiseaseAnalysisResult>(
                                  builder: (_) => AiAnalysisDetailPage(
                                    photo: photo,
                                    prediction: prediction,
                                    detail: detail,
                                    confidencePercent: confidencePercent,
                                    analysisService: service,
                                    diseaseDetails: diseaseDetails,
                                  ),
                                ),
                              );
                          if (context.mounted && updated != null) {
                            setState(() => currentAnalysis = updated);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFF146B2E),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Lihat Detail AI & Penanganan',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            color: const Color(0xFF064E2B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Informasi model dan panduan lengkap untuk '
                                      '${detail.name}.',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: const Color(0xFF365342),
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF146B2E),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        scannedAtLabel == null
                            ? 'Kembali ke Scan'
                            : 'Kembali ke Riwayat',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

String _managementSummary(String? management) {
  final paragraphs = management?.split(RegExp(r'\n\s*\n'));
  final firstParagraph = paragraphs == null || paragraphs.isEmpty
      ? null
      : paragraphs.first.trim();
  return firstParagraph == null || firstParagraph.isEmpty
      ? 'Rekomendasi belum tersedia.'
      : firstParagraph;
}

class _AnalysisStatusLine extends StatelessWidget {
  const _AnalysisStatusLine({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text('$title: $value'),
  );
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
