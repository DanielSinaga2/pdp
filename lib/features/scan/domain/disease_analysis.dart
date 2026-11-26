import '../../knowledge/domain/condition_label.dart';
import '../../knowledge/domain/disease_detail_repository.dart';
import 'certainty_factor.dart';
import 'fuzzy_logic.dart';
import 'prediction_repository.dart';

enum AnalysisCompleteness { notCalculated, partiallyCalculated, calculated }

enum ChemicalActionLevel { notNeeded, monitor, recommended }

class AnalysisRecommendation {
  const AnalysisRecommendation({required this.category, required this.content});

  final String category;
  final String content;
}

class DiseaseAnalysisResult {
  const DiseaseAnalysisResult({
    required this.predictedDisease,
    required this.cnnConfidence,
    required this.certaintyResult,
    required this.certaintyResults,
    required this.fuzzyResult,
    required this.severityInputPercent,
    required this.environmentalEvidenceStatus,
    required this.recommendations,
    required this.completeness,
    required this.isSimulated,
    required this.conflictsWithPrediction,
    required this.diagnosisCertain,
    required this.diagnosisCandidate,
    required this.diagnosisCandidateScore,
    required this.chemicalActionLevel,
  });

  final ConditionLabel predictedDisease;
  final double cnnConfidence;
  final CertaintyResult certaintyResult;
  final Map<ConditionLabel, CertaintyResult> certaintyResults;
  final FuzzyResult fuzzyResult;
  final double? severityInputPercent;
  final String environmentalEvidenceStatus;
  final List<AnalysisRecommendation> recommendations;
  final AnalysisCompleteness completeness;
  final bool isSimulated;
  final bool conflictsWithPrediction;
  final bool diagnosisCertain;
  final ConditionLabel? diagnosisCandidate;
  final double? diagnosisCandidateScore;
  final ChemicalActionLevel? chemicalActionLevel;
}

class DiseaseAnalysisService {
  static const double certaintyThreshold = 0.50;
  static const double certaintyMarginThreshold = 0.15;

  DiseaseAnalysisService({
    required Iterable<ExpertRule> expertRules,
    required this.fuzzyEngine,
  }) : expertRules = List.unmodifiable(expertRules);

  factory DiseaseAnalysisService.fromNotebookDraft() => DiseaseAnalysisService(
    expertRules: NotebookExpertRules.rules,
    fuzzyEngine: FuzzyLogicEngine(FuzzyConfiguration.fromNotebookDraft()),
  );

  final List<ExpertRule> expertRules;
  final FuzzyLogicEngine fuzzyEngine;
  final CertaintyFactorCalculator _certaintyCalculator =
      const CertaintyFactorCalculator();

  DiseaseAnalysisResult analyze({
    required ScanPrediction prediction,
    required Iterable<SymptomObservation> observations,
    required FuzzyInputs fuzzyInputs,
    required DiseaseDetail diseaseDetail,
  }) {
    final selectedObservations = [
      ...observations,
      ..._environmentObservations(fuzzyInputs),
    ];
    final environmentalEvidenceStatus = _environmentalEvidenceStatus(
      fuzzyInputs,
    );
    final conditions = ConditionLabel.values.where(
      (condition) => condition != ConditionLabel.healthy,
    );
    final certaintyByDisease = <ConditionLabel, CertaintyResult>{
      for (final condition in conditions)
        condition: _certaintyCalculator.calculate(
          condition: condition,
          observations: selectedObservations,
          rules: expertRules,
        ),
    };
    final certainty =
        certaintyByDisease[prediction.label] ??
        _notCalculated(prediction.label);
    final hasEvidence = certaintyByDisease.values.any(
      (result) => result.isCalculated,
    );
    final ranked = certaintyByDisease.values.toList()
      ..sort(
        (first, second) =>
            (second.score ?? 0).compareTo(first.score ?? 0),
      );
    final top = hasEvidence ? ranked.first : null;
    final topScore = top?.score ?? 0;
    final secondScore = ranked.length > 1 ? ranked[1].score ?? 0 : 0.0;
    final diagnosisCertain =
        top != null &&
        topScore >= certaintyThreshold &&
        topScore - secondScore >= certaintyMarginThreshold;
    final conflicting =
        diagnosisCertain && top.condition != prediction.label;
    final fuzzy = fuzzyEngine.calculate(
      fuzzyInputs,
      {
        for (final entry in certaintyByDisease.entries)
          entry.key: entry.value.score,
      },
    );
    final chemicalAction = _chemicalAction(
      fuzzy,
      diagnosisCertain: diagnosisCertain,
      daysAfterTransplant: fuzzyInputs.daysAfterTransplant,
    );
    final recommendations = _recommendations(
      prediction.label,
      diseaseDetail,
      chemicalAction,
      daysAfterTransplant: fuzzyInputs.daysAfterTransplant,
    );
    final hasCertainty = hasEvidence;
    final complete = hasCertainty && fuzzy.isCalculated;

    return DiseaseAnalysisResult(
      predictedDisease: prediction.label,
      cnnConfidence: prediction.confidence,
      certaintyResult: certainty,
      certaintyResults: Map.unmodifiable(certaintyByDisease),
      fuzzyResult: fuzzy,
      severityInputPercent: fuzzyInputs.severityPercent,
      environmentalEvidenceStatus: environmentalEvidenceStatus,
      recommendations: List.unmodifiable(recommendations),
      completeness: complete
          ? AnalysisCompleteness.calculated
          : hasCertainty || fuzzy.isCalculated
          ? AnalysisCompleteness.partiallyCalculated
          : AnalysisCompleteness.notCalculated,
      isSimulated: prediction.isSimulated,
      conflictsWithPrediction: conflicting,
      diagnosisCertain: diagnosisCertain,
      diagnosisCandidate: top?.condition,
      diagnosisCandidateScore: top?.score,
      chemicalActionLevel: chemicalAction,
    );
  }

  List<SymptomObservation> _environmentObservations(FuzzyInputs input) {
    final degrees = fuzzyEngine.environmentalEvidence(input);
    return [
      for (final item in degrees)
        if (item.degree > 0)
          SymptomObservation(
            symptomId: item.id,
            symptomName: item.name,
            userConfidence: item.degree,
            isEnvironmental: true,
          ),
    ];
  }

  String _environmentalEvidenceStatus(FuzzyInputs input) {
    if (!input.hasEnvironmentalEvidenceInputs) {
      return 'Evidence lingkungan belum dipakai: isi suhu, RH, curah hujan '
          '7 hari, dan HST agar dihitung sesuai notebook.';
    }
    if (fuzzyEngine.environmentalEvidence(input).isEmpty) {
      return 'Evidence lingkungan tidak dipakai karena ada input di luar '
          'rentang membership notebook.';
    }
    return 'Evidence lingkungan dihitung dari membership suhu, RH, hujan, '
        'dan HST; hanya degree positif yang masuk ke CF.';
  }

  CertaintyResult _notCalculated(ConditionLabel condition) => CertaintyResult(
    condition: condition,
    status: CertaintyStatus.notCalculated,
    evidence: const [],
    steps: const [],
    missingRuleIds: const [],
  );

  ChemicalActionLevel? _chemicalAction(
    FuzzyResult fuzzy, {
    required bool diagnosisCertain,
    required double? daysAfterTransplant,
  }) {
    final score = fuzzy.chemicalScore;
    if (!fuzzy.isCalculated || score == null) return null;
    if (!diagnosisCertain ||
        (daysAfterTransplant != null && daysAfterTransplant > 85)) {
      return ChemicalActionLevel.notNeeded;
    }
    if (score >= 0.60) return ChemicalActionLevel.recommended;
    if (score >= 0.30) return ChemicalActionLevel.monitor;
    return ChemicalActionLevel.notNeeded;
  }

  List<AnalysisRecommendation> _recommendations(
    ConditionLabel condition,
    DiseaseDetail detail,
<<<<<<< HEAD
    ChemicalActionLevel? chemicalAction, {
    required double? daysAfterTransplant,
  }) {
    final management = [
      detail.management,
      detail.analysisManagement,
    ]
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
    if (management.isEmpty) return const [];
=======
    ChemicalActionLevel? chemicalAction,
    {required double? daysAfterTransplant}
  ) {
    final management = detail.management?.trim();
    if (management == null || management.isEmpty) return const [];
>>>>>>> b5964916dfbca4f875866580e6dbe970d46a4ef0
    final canRecommendUrea =
        daysAfterTransplant != null &&
        daysAfterTransplant.isFinite &&
        daysAfterTransplant >= 0 &&
        daysAfterTransplant <= FuzzyLogicEngine.ureaStopAfterHst;
    final recommendationContent = canRecommendUrea
        ? management
        : _withoutUreaAdvice(management);
    if (condition == ConditionLabel.healthy) {
      return [
        AnalysisRecommendation(
          category: 'Perawatan tanaman sehat',
          content: recommendationContent,
        ),
      ];
    }

    final category = switch (chemicalAction) {
      ChemicalActionLevel.recommended =>
        'Rujuk pengendalian kepada penyuluh (skor Sugeno memenuhi ambang)',
      ChemicalActionLevel.monitor =>
        'Pemantauan dan konsultasi (skor Sugeno pada rentang siaga)',
      ChemicalActionLevel.notNeeded =>
        'Panduan awal berdasarkan referensi; jangan otomatis menyemprot',
      null => 'Panduan awal berdasarkan referensi aplikasi',
    };
    return [
      AnalysisRecommendation(
        category: category,
        content: recommendationContent,
      ),
    ];
  }
}

String _withoutUreaAdvice(String management) {
  final keptLines = <String>[];
  var suppressWrappedLines = false;
  for (final line in management.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      suppressWrappedLines = false;
      if (keptLines.isNotEmpty && keptLines.last.isNotEmpty) {
        keptLines.add('');
      }
      continue;
    }

    if (trimmed.startsWith('•')) {
      suppressWrappedLines = trimmed.toLowerCase().contains('urea');
      if (!suppressWrappedLines) keptLines.add(line);
      continue;
    }

    if (trimmed.toLowerCase().contains('urea')) {
      suppressWrappedLines = true;
      continue;
    }
    if (!suppressWrappedLines) keptLines.add(line);
  }
  return keptLines.join('\n').trim();
}
