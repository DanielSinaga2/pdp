import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';

import '../../knowledge/domain/condition_label.dart';
import '../../knowledge/domain/disease_detail_repository.dart';
import '../domain/certainty_factor.dart';
import '../domain/disease_analysis.dart';
import '../domain/fuzzy_logic.dart';
import '../domain/prediction_repository.dart';

const _primaryGreen = Color(0xFF146B2E);
const _darkGreen = Color(0xFF064E2B);
const _lightGreen = Color(0xFFEAF5DF);
const _pageBackground = Color(0xFFFAFCF5);
const _disclaimer =
    'Informasi ini merupakan panduan awal berdasarkan hasil analisis dan '
    'referensi yang tersedia. Hasil AI bukan pengganti pemeriksaan langsung '
    'oleh ahli pertanian atau penyuluh lapangan.';

class AiAnalysisDetailPage extends StatefulWidget {
  const AiAnalysisDetailPage({
    super.key,
    required this.photo,
    required this.prediction,
    required this.detail,
    required this.confidencePercent,
    this.analysisService,
    this.diseaseDetails,
  });

  final Uint8List? photo;
  final ScanPrediction prediction;
  final DiseaseDetail detail;
  final int confidencePercent;
  final DiseaseAnalysisService? analysisService;
  final DiseaseDetailRepository? diseaseDetails;

  @override
  State<AiAnalysisDetailPage> createState() => _AiAnalysisDetailPageState();
}

class _AiAnalysisDetailPageState extends State<AiAnalysisDetailPage> {
  final Map<String, double?> _answers = {};
  double? _severityPercent;
  double? _daysAfterTransplant;
  double? _relativeHumidity;
  double? _temperature;
  double? _rainfall;

  DiseaseAnalysisService get _service =>
      widget.analysisService ?? DiseaseAnalysisService.fromNotebookDraft();

  List<ExpertRule> get _questions => NotebookExpertRules.rules
      .where((rule) => !rule.isEnvironmental)
      .fold(<String, ExpertRule>{}, (questions, rule) {
        questions.putIfAbsent(rule.symptomId, () => rule);
        return questions;
      })
      .values
      .toList();

  List<SymptomObservation> get _observations => [
    for (final question in _questions)
      if (_answers[question.symptomId] case final confidence?)
        SymptomObservation(
          symptomId: question.symptomId,
          symptomName: question.symptomName,
          userConfidence: confidence,
        ),
  ];

  DiseaseAnalysisResult _analyze() => _service.analyze(
    prediction: widget.prediction,
    observations: _observations,
    fuzzyInputs: FuzzyInputs(
      severityPercent: _severityPercent,
      daysAfterTransplant: _daysAfterTransplant,
      relativeHumidityPercent: _relativeHumidity,
      temperatureCelsius: _temperature,
      rainfallLast7DaysMm: _rainfall,
    ),
    diseaseDetail: widget.detail,
  );

  @override
  Widget build(BuildContext context) {
    final analysis = _analyze();
    final lowConfidence =
        widget.prediction.confidence < widget.confidencePercent / 100;
    final isHealthy = widget.prediction.label == ConditionLabel.healthy;
    final theme = Theme.of(context);

    return PopScope<DiseaseAnalysisResult>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(analysis);
      },
      child: Scaffold(
      backgroundColor: _pageBackground,
      appBar: AppBar(
        title: const Text('Detail AI & Penanganan'),
        backgroundColor: _pageBackground,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _SectionHeading(
                  icon: Icons.memory_outlined,
                  title: 'Model AI / CNN',
                ),
                _InfoCard(
                  children: [
                    Text(
                      'PaddySehat Image Classification Model',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: _darkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Model mengklasifikasikan citra daun padi menggunakan '
                      'TensorFlow Lite. Inferensi dilakukan langsung di '
                      'perangkat pengguna.',
                    ),
                    const SizedBox(height: 14),
                    const _LabelValue(
                      label: 'Framework',
                      value: 'TensorFlow Lite',
                    ),
                    const _LabelValue(
                      label: 'Arsitektur',
                      value:
                          'Notebook menggunakan EfficientNetB0 sebagai '
                          'default (MobileNetV2 tersedia sebagai opsi). '
                          'Model aplikasi mengikuti metadata berkas model.',
                    ),
                    const _LabelValue(
                      label: 'Metode',
                      value: 'Klasifikasi citra daun padi',
                    ),
                    const _LabelValue(label: 'Input', value: 'Foto daun padi'),
                    const _LabelValue(
                      label: 'Output',
                      value: 'Klasifikasi kondisi atau penyakit daun padi',
                    ),
                    const _LabelValue(
                      label: 'Inferensi',
                      value: 'On-device inference',
                    ),
                    _LabelValue(
                      label: 'Status model',
                      value: widget.prediction.isSimulated
                          ? 'Simulasi'
                          : 'Model asli (TensorFlow Lite)',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: Icons.center_focus_strong_outlined,
                  title: 'Hasil CNN',
                ),
                _InfoCard(
                  children: [
                    if (widget.photo case final image?) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          image,
                          height: 190,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          semanticLabel: 'Foto daun padi yang dianalisis',
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 100,
                            child: Center(
                              child: Text('Foto tidak dapat dibaca.'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else
                      const Text('Salinan foto tidak tersedia.'),
                    Text(
                      widget.detail.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _darkGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _LabelValue(
                      label: 'Probabilitas keluaran CNN',
                      value: _formatPercent(widget.prediction.confidence),
                    ),
                    const Text(
                      'Nilai ini adalah probabilitas model untuk label terpilih, '
                      'bukan nilai Certainty Factor.',
                    ),
                    if (lowConfidence) ...[
                      const SizedBox(height: 12),
                      _Notice(
                        text:
                            'Confidence CNN di bawah '
                            '${widget.confidencePercent}%. Identifikasi belum '
                            'meyakinkan. Rekomendasi berdasarkan label prediksi '
                            'bersifat awal; ambil foto ulang dengan pencahayaan '
                            'lebih baik atau konsultasikan kepada penyuluh.',
                        warning: true,
                      ),
                    ],
                    if (analysis.conflictsWithPrediction) ...[
                      const SizedBox(height: 12),
                      _Notice(
                        text:
                            'Bukti gejala memberi dukungan CF lebih tinggi '
                            'pada ${_conditionName(analysis.diagnosisCandidate)} '
                            'daripada label CNN ${widget.detail.name}. Hasil '
                            'tidak disamakan otomatis; verifikasi gejala atau '
                            'lakukan pemeriksaan ulang.',
                        warning: true,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: Icons.fact_check_outlined,
                  title: 'Gejala Notebook',
                ),
                const Text(
                  'Pilih tingkat keyakinan sesuai pengamatan. Pilihan '
                  '"Tidak" bernilai 0 dan tidak menambahkan evidence CF.',
                ),
                const SizedBox(height: 10),
                for (final question in _questions)
                  _SymptomQuestionCard(
                    question: question,
                    confidence: _answers[question.symptomId],
                    onChanged: (value) =>
                        setState(() => _answers[question.symptomId] = value),
                  ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: Icons.cloud_outlined,
                  title: 'Data Lingkungan dan Tanaman',
                ),
                const Text(
                  'Input ini digunakan sesuai variabel notebook. Suhu, hujan, '
                  'RH, dan HST harus lengkap agar bukti lingkungan dapat '
                  'ditambahkan ke perhitungan CF.',
                ),
                _FuzzyInputCard(
                  title: 'Keparahan gejala',
                  help: 'Persentase 0-100%',
                  value: _severityPercent,
                  onChanged: (value) =>
                      setState(() => _severityPercent = value),
                ),
                _FuzzyInputCard(
                  title: 'Umur tanaman (HST)',
                  help: 'Hari setelah tanam',
                  value: _daysAfterTransplant,
                  onChanged: (value) =>
                      setState(() => _daysAfterTransplant = value),
                ),
                _FuzzyInputCard(
                  title: 'Kelembapan udara (RH)',
                  help: 'Persentase 0-100%',
                  value: _relativeHumidity,
                  onChanged: (value) =>
                      setState(() => _relativeHumidity = value),
                ),
                _FuzzyInputCard(
                  title: 'Suhu (°C)',
                  help: 'Digunakan untuk evidence lingkungan CF',
                  value: _temperature,
                  onChanged: (value) => setState(() => _temperature = value),
                ),
                _FuzzyInputCard(
                  title: 'Curah hujan 7 hari (mm)',
                  help: 'Digunakan untuk evidence lingkungan CF',
                  value: _rainfall,
                  onChanged: (value) => setState(() => _rainfall = value),
                ),
                _Notice(
                  text: analysis.environmentalEvidenceStatus,
                  warning: !analysis.environmentalEvidenceStatus.startsWith(
                    'Evidence lingkungan dihitung',
                  ),
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: Icons.calculate_outlined,
                  title: 'Certainty Factor',
                ),
                _CertaintyCard(
                  result: analysis.certaintyResult,
                  allResults: analysis.certaintyResults,
                  observations: _observations,
                  hasPartialAnswers: _answers.values.any(
                    (confidence) => confidence != null,
                  ),
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: Icons.tune_outlined,
                  title: 'Fuzzy Sugeno',
                ),
                const Text(
                  'Notebook memakai keparahan gejala, HST, dan RH untuk '
                  'menghitung faktor Urea, faktor KCl, dan skor pengendalian '
                  'kimia. Ini bukan dosis dan bukan diagnosis mandiri.',
                ),
                const SizedBox(height: 10),
                _FuzzyResultCard(
                  result: analysis.fuzzyResult,
                  actionLevel: analysis.chemicalActionLevel,
                  severityPercent: analysis.severityInputPercent,
                ),
                const SizedBox(height: 22),
                _SectionHeading(
                  icon: isHealthy
                      ? Icons.eco_outlined
                      : Icons.health_and_safety_outlined,
                  title: isHealthy ? 'Perawatan Tanaman' : 'Rekomendasi',
                ),
                for (final recommendation in analysis.recommendations)
                  _RecommendationCard(recommendation: recommendation),
                if (analysis.recommendations.isEmpty)
                  const _Notice(
                    text: 'Rekomendasi belum tersedia pada referensi aplikasi.',
                  ),
                if (widget.detail.needsReview) ...[
                  const SizedBox(height: 8),
                  const _Notice(
                    text:
                        'Materi penanganan ini masih memerlukan tinjauan ahli.',
                  ),
                ],
                const SizedBox(height: 18),
                const _Notice(text: _disclaimer),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(icon, color: _primaryGreen),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(color: _darkGreen, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: _primaryGreen, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(value),
      ],
    ),
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) => Card(
    color: warning ? const Color(0xFFFFF3D6) : _lightGreen,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            warning ? Icons.warning_amber_rounded : Icons.info_outline,
            color: warning ? const Color(0xFF805900) : _primaryGreen,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    ),
  );
}

class _SymptomQuestionCard extends StatelessWidget {
  const _SymptomQuestionCard({
    required this.question,
    required this.confidence,
    required this.onChanged,
  });

  final ExpertRule question;
  final double? confidence;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.symptomName),
          const SizedBox(height: 10),
          DropdownButtonFormField<double>(
            key: ValueKey('symptom_${question.symptomId}'),
            initialValue: confidence,
            decoration: const InputDecoration(
              labelText: 'Keyakinan sesuai notebook',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 0, child: Text('Tidak (0.0)')),
              DropdownMenuItem(value: 0.4, child: Text('Ragu (0.4)')),
              DropdownMenuItem(
                value: 0.6,
                child: Text('Cukup yakin (0.6)'),
              ),
              DropdownMenuItem(value: 0.8, child: Text('Yakin (0.8)')),
              DropdownMenuItem(
                value: 1,
                child: Text('Sangat yakin (1.0)'),
              ),
            ],
            onChanged: onChanged,
          ),
        ],
      ),
    ),
  );
}

class _CertaintyCard extends StatelessWidget {
  const _CertaintyCard({
    required this.result,
    required this.allResults,
    required this.observations,
    required this.hasPartialAnswers,
  });

  final CertaintyResult result;
  final Map<ConditionLabel, CertaintyResult> allResults;
  final List<SymptomObservation> observations;
  final bool hasPartialAnswers;

  @override
  Widget build(BuildContext context) {
    final message = switch (result.status) {
      CertaintyStatus.calculated =>
        'CF penyakit ini: ${result.score!.toStringAsFixed(3)} '
            '(${(result.score! * 100).toStringAsFixed(1)}%). Nilai ini '
            'dihitung terpisah dari probabilitas CNN.',
      CertaintyStatus.incompleteExpertRules =>
        'CF belum dapat dihitung karena ada evidence yang tidak memiliki '
            'aturan notebook: ${result.missingRuleIds.join(', ')}.',
      CertaintyStatus.notCalculated =>
        observations.isEmpty && !hasPartialAnswers
            ? 'CF belum dapat dihitung karena belum ada evidence yang dipilih.'
            : 'CF untuk label prediksi belum memiliki evidence yang dapat '
                  'dihitung.',
    };

    return _InfoCard(
      children: [
        _Notice(text: message, warning: !result.isCalculated),
        const SizedBox(height: 10),
        const Text(
          'CF evidence = CF pakar bertanda × keyakinan pengguna. '
          'CF+ = 1 − Π(1 − CF positif); CF− = 1 − Π(1 − |CF negatif|); '
          'CF akhir = (CF+ − CF−) / (1 − min(CF+, CF−)).',
        ),
        for (final entry in allResults.entries)
          if (entry.value.score != null)
            Text(
              '${_conditionName(entry.key)}: '
              '${entry.value.score!.toStringAsFixed(3)}',
            ),
        if (observations.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Evidence gejala yang dipilih:'),
          for (final observation in observations)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${observation.symptomId} · '
                'CF pengguna ${observation.userConfidence.toStringAsFixed(1)}\n'
                '${observation.symptomName}',
              ),
            ),
        ],
        if (result.evidence.isNotEmpty) ...[
          const SizedBox(height: 12),
          for (final evidence in result.evidence)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${evidence.isEnvironmental ? 'Lingkungan' : 'Gejala'} · '
                '${_conditionName(evidence.condition)} · '
                '${evidence.symptomName}\n'
                'CF pakar ${evidence.expertWeight.toStringAsFixed(2)} × '
                'keyakinan pengguna '
                '${evidence.userConfidence.toStringAsFixed(2)} = '
                'CF evidence ${evidence.cfValue.toStringAsFixed(3)}',
              ),
            ),
          for (var index = 0; index < result.steps.length; index++)
            Text(
              'Agregasi notebook: CF+ '
              '${result.steps[index].positiveEvidence.toStringAsFixed(3)}, '
              'CF− ${result.steps[index].negativeEvidence.toStringAsFixed(3)}, '
              'CF akhir ${result.steps[index].combined.toStringAsFixed(3)}.',
            ),
        ],
      ],
    );
  }
}

class _FuzzyInputCard extends StatelessWidget {
  const _FuzzyInputCard({
    required this.title,
    required this.help,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String help;
  final double? value;
  final ValueChanged<double?> onChanged;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: TextFormField(
        key: ValueKey('fuzzy_$title'),
        initialValue: value?.toString(),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: title,
          helperText: help,
          border: const OutlineInputBorder(),
        ),
        onChanged: (text) => onChanged(double.tryParse(text)),
      ),
    ),
  );
}

class _FuzzyResultCard extends StatelessWidget {
  const _FuzzyResultCard({
    required this.result,
    required this.actionLevel,
    required this.severityPercent,
  });

  final FuzzyResult result;
  final ChemicalActionLevel? actionLevel;
  final double? severityPercent;

  @override
  Widget build(BuildContext context) {
    if (!result.isCalculated) {
      return _InfoCard(
        children: [
          _Notice(text: result.message ?? 'Fuzzy belum dapat dihitung.'),
          if (!result.configurationValidated) ...[
            const SizedBox(height: 8),
            const _Notice(
              text: 'Aturan dan rentang berasal dari notebook, tetapi tetap '
                  'memerlukan validasi ahli pertanian sebelum penggunaan '
                  'sebagai keputusan budidaya.',
            ),
          ],
        ],
      );
    }

    return _InfoCard(
      children: [
        Text(
          'Input keparahan: ${severityPercent?.toStringAsFixed(0) ?? '-'}%',
        ),
        Text(
          'Faktor Urea Sugeno: ${result.ureaFactor!.toStringAsFixed(2)}',
        ),
        Text(
          'Faktor Urea setelah aturan fase notebook: '
          '${result.ureaFactorAfterGrowthStage!.toStringAsFixed(2)}',
        ),
        Text('Faktor KCl Sugeno: ${result.kclFactor!.toStringAsFixed(2)}'),
        Text(
          'Skor pengendalian kimia: '
          '${result.chemicalScore!.toStringAsFixed(2)}',
        ),
        if (actionLevel != null)
          Text(
            'Tindak lanjut notebook: ${switch (actionLevel!) {
              ChemicalActionLevel.notNeeded => 'tidak diperlukan',
              ChemicalActionLevel.monitor => 'siaga / pantau',
              ChemicalActionLevel.recommended => 'disarankan',
            }}',
          ),
        if (!result.configurationValidated) ...[
          const SizedBox(height: 8),
          _Notice(text: result.message ?? 'Parameter fuzzy belum divalidasi.'),
        ],
        const SizedBox(height: 12),
        const Text('Derajat keanggotaan input:'),
        for (final variable in result.inputMemberships.entries)
          Text(
            '${variable.key}: ${variable.value.entries.map((entry) => '${entry.key} ${entry.value.toStringAsFixed(2)}').join(', ')}',
          ),
        const SizedBox(height: 8),
        const Text('Aturan Sugeno aktif (AND = minimum; CF dipangkatkan 3):'),
        for (final activation in result.activeRules)
          Text(
            '${activation.rule.id} (${_conditionName(activation.rule.condition)}): '
            '${activation.rule.antecedents} → Urea ×'
            '${activation.rule.ureaFactor}, KCl ×${activation.rule.kclFactor}, '
            'skor kimia ${activation.rule.chemicalScore} '
            '(μ=${activation.membershipStrength.toStringAsFixed(2)}, '
            'bobot CF=${activation.cfWeight.toStringAsFixed(3)}, '
            'w=${activation.weight.toStringAsFixed(3)})',
          ),
        const SizedBox(height: 8),
        const Text(
          'Metode: Sugeno orde-0, kekuatan aturan min(μ) × max(CF, 0)³, '
          'keluaran crisp berupa rata-rata terbobot.',
        ),
        const SizedBox(height: 8),
        const _Notice(
          text: 'Nilai di atas adalah faktor dan skor sistem, bukan dosis '
              'pupuk/pestisida. Ikuti referensi penanganan aplikasi dan '
              'konsultasikan dengan penyuluh.',
          warning: true,
        ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final AnalysisRecommendation recommendation;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            recommendation.category,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: _darkGreen, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(recommendation.content),
        ],
      ),
    ),
  );
}

String _conditionName(ConditionLabel? condition) => switch (condition) {
  ConditionLabel.bacterialLeafBlight => 'Hawar daun bakteri',
  ConditionLabel.blast => 'Blast',
  ConditionLabel.brownSpot => 'Bercak coklat',
  ConditionLabel.tungro => 'Tungro',
  ConditionLabel.healthy => 'Sehat',
  null => 'kondisi tidak diketahui',
};

String _formatPercent(double value) =>
    '${(value * 100).toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '').replaceFirst('.', ',')}%';
