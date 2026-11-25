import 'package:flutter_test/flutter_test.dart';
import 'package:pdp/features/knowledge/data/local_disease_detail_repository.dart';
import 'package:pdp/features/knowledge/domain/condition_label.dart';
import 'package:pdp/features/scan/domain/certainty_factor.dart';
import 'package:pdp/features/scan/domain/disease_analysis.dart';
import 'package:pdp/features/scan/domain/fuzzy_logic.dart';
import 'package:pdp/features/scan/domain/prediction_repository.dart';

void main() {
  const details = LocalDiseaseDetailRepository();
  final configuration = FuzzyConfiguration.fromNotebookDraft();
  final engine = FuzzyLogicEngine(configuration);

  SymptomObservation observation({
    String id = 'G05',
    String name = 'Bercak berbentuk belah ketupat',
    double confidence = 0.8,
  }) => SymptomObservation(
    symptomId: id,
    symptomName: name,
    userConfidence: confidence,
  );

  ExpertRule rule({
    String id = 'G05',
    String name = 'Bercak berbentuk belah ketupat',
    ConditionLabel condition = ConditionLabel.blast,
    double weight = 0.8,
  }) => ExpertRule(
    symptomId: id,
    symptomName: name,
    condition: condition,
    expertWeight: weight,
  );

  test('CF satu evidence mengalikan CF pakar bertanda dan CF pengguna', () {
    final result = const CertaintyFactorCalculator().calculate(
      condition: ConditionLabel.blast,
      observations: [observation(confidence: 0.6)],
      rules: [rule()],
    );

    expect(result.isCalculated, isTrue);
    expect(result.evidence.single.cfValue, closeTo(0.48, 1e-10));
    expect(result.score, closeTo(0.48, 1e-10));
  });

  test('CF menggunakan agregasi positif-negatif persis seperti notebook', () {
    final result = const CertaintyFactorCalculator().calculate(
      condition: ConditionLabel.blast,
      observations: [
        observation(id: 'positive-a', confidence: 1),
        observation(id: 'positive-b', confidence: 0.5),
        observation(id: 'negative', confidence: 1),
      ],
      rules: [
        rule(id: 'positive-a', weight: 0.8),
        rule(id: 'positive-b', weight: 0.4),
        rule(id: 'negative', weight: -0.3),
      ],
    );

    // CF+ = 1 - (1 - 0.8)(1 - 0.2) = 0.84; CF- = 0.3.
    // CF = (0.84 - 0.3) / (1 - 0.3) = 0.771428...
    expect(result.steps.single.positiveEvidence, closeTo(0.84, 1e-10));
    expect(result.steps.single.negativeEvidence, closeTo(0.3, 1e-10));
    expect(result.score, closeTo(0.54 / 0.7, 1e-10));
  });

  test('bobot gejala dan aturan negatif sesuai notebook', () {
    final rules = NotebookExpertRules.rules;
    expect(
      rules
          .where((rule) => !rule.isEnvironmental)
          .map((r) => r.symptomId)
          .toSet()
          .length,
      16,
    );
    expect(
      rules
          .where((rule) => rule.isEnvironmental)
          .map((r) => r.symptomId)
          .toSet()
          .length,
      6,
    );
    expect(
      rules
          .singleWhere(
            (item) =>
                item.symptomId == 'G05' &&
                item.condition == ConditionLabel.brownSpot,
          )
          .expertWeight,
      -0.3,
    );
    expect(
      rules
          .singleWhere(
            (item) =>
                item.symptomId == 'G15' &&
                item.condition == ConditionLabel.blast,
          )
          .expertWeight,
      -0.3,
    );
    expect(NotebookExpertRules.userConfidenceLevels, [0, 0.4, 0.6, 0.8, 1]);
  });

  test('CF tanpa evidence dan jawaban Tidak tidak menghasilkan diagnosis', () {
    const calculator = CertaintyFactorCalculator();
    final empty = calculator.calculate(
      condition: ConditionLabel.blast,
      observations: const [],
      rules: NotebookExpertRules.rules,
    );
    final notObserved = calculator.calculate(
      condition: ConditionLabel.blast,
      observations: [observation(confidence: 0)],
      rules: NotebookExpertRules.rules,
    );

    expect(empty.status, CertaintyStatus.notCalculated);
    expect(empty.score, isNull);
    expect(notObserved.status, CertaintyStatus.notCalculated);
    expect(notObserved.score, isNull);
  });

  test('CF melaporkan evidence tanpa aturan yang dikenal', () {
    final result = const CertaintyFactorCalculator().calculate(
      condition: ConditionLabel.blast,
      observations: [observation(id: 'unknown')],
      rules: NotebookExpertRules.rules,
    );

    expect(result.status, CertaintyStatus.incompleteExpertRules);
    expect(result.score, isNull);
    expect(result.missingRuleIds, ['unknown']);
  });

  test('membership trapezoid memakai batas yang ditetapkan notebook', () {
    final severity = configuration.memberships['severity']!['ringan']!;
    expect(severity.degree(0), 1);
    expect(severity.degree(4), 1);
    expect(severity.degree(7), closeTo(0.5, 1e-10));
    expect(severity.degree(10), 0);

    final humidity = configuration.memberships['humidity']!['tinggi']!;
    expect(humidity.degree(80), 0);
    expect(humidity.degree(90), 1);
    expect(humidity.degree(100), 1);
  });

  test('evidence lingkungan memakai MF hujan, RH, suhu, dan HST notebook', () {
    final result = engine.environmentalEvidence(
      const FuzzyInputs(
        daysAfterTransplant: 25,
        relativeHumidityPercent: 90,
        temperatureCelsius: 20,
        rainfallLast7DaysMm: 150,
      ),
    );

    expect(result, hasLength(6));
    expect(result.singleWhere((item) => item.id == 'E01').degree, 1);
    expect(result.singleWhere((item) => item.id == 'E02').degree, 1);
    expect(result.singleWhere((item) => item.id == 'E03').degree, 1);
    expect(result.singleWhere((item) => item.id == 'E05').degree, 1);
  });

  test('Sugeno memerlukan keparahan, HST, RH dan CF positif', () {
    final incomplete = engine.calculate(
      const FuzzyInputs(severityPercent: 50, daysAfterTransplant: 40),
      const {ConditionLabel.blast: 0.8},
    );
    final noEvidence = engine.calculate(
      const FuzzyInputs(
        severityPercent: 50,
        daysAfterTransplant: 40,
        relativeHumidityPercent: 85,
      ),
      const {ConditionLabel.blast: 0},
    );

    expect(incomplete.status, FuzzyStatus.notCalculated);
    expect(noEvidence.status, FuzzyStatus.notCalculated);
    expect(noEvidence.chemicalScore, isNull);
  });

  test('Sugeno memakai weight membership min dikali CF pangkat tiga', () {
    final result = engine.calculate(
      const FuzzyInputs(
        severityPercent: 0,
        daysAfterTransplant: 0,
        relativeHumidityPercent: 50,
      ),
      const {ConditionLabel.bacterialLeafBlight: 0.8},
    );
    final dominant = result.activeRules.first;

    expect(result.status, FuzzyStatus.calculated);
    expect(result.configurationValidated, isFalse);
    expect(dominant.rule.condition, ConditionLabel.bacterialLeafBlight);
    expect(dominant.membershipStrength, 1);
    expect(dominant.cfWeight, closeTo(0.8 * 0.8 * 0.8, 1e-10));
    expect(result.ureaFactor, closeTo(0.8, 1e-10));
    expect(result.kclFactor, closeTo(1.3, 1e-10));
    expect(result.chemicalScore, closeTo(0.1, 1e-10));
    expect(result.activeRules, hasLength(1));
  });

  test('Sugeno mengikuti pagar Urea pada fase berbunga dan pemasakan', () {
    final result = engine.calculate(
      const FuzzyInputs(
        severityPercent: 50,
        daysAfterTransplant: 70,
        relativeHumidityPercent: 70,
      ),
      const {ConditionLabel.blast: 0.8},
    );

    expect(result.status, FuzzyStatus.calculated);
    expect(result.ureaFactor, greaterThan(0));
    expect(result.ureaFactorAfterGrowthStage, 0);
  });

  test('service membandingkan CF dengan CNN tanpa menyatukan probabilitas', () {
    final service = DiseaseAnalysisService.fromNotebookDraft();
    final result = service.analyze(
      prediction: const ScanPrediction(
        label: ConditionLabel.blast,
        confidence: 0.42,
        isSimulated: true,
      ),
      observations: [
        observation(
          id: 'G12',
          name: 'Daun menguning-oranye dimulai dari ujung daun',
          confidence: 1,
        ),
      ],
      fuzzyInputs: const FuzzyInputs(
        severityPercent: 50,
        daysAfterTransplant: 40,
        relativeHumidityPercent: 85,
      ),
      diseaseDetail: details.getDetail(ConditionLabel.blast),
    );

    expect(result.cnnConfidence, 0.42);
    expect(result.isSimulated, isTrue);
    expect(result.certaintyResult.score, isNull);
    expect(result.conflictsWithPrediction, isTrue);
    expect(result.diagnosisCandidate, ConditionLabel.tungro);
    expect(result.fuzzyResult.isCalculated, isTrue);
    expect(
      result.environmentalEvidenceStatus,
      contains('Evidence lingkungan belum dipakai'),
    );
  });

  test('ambang notebook mengizinkan tindak lanjut hanya jika CF yakin', () {
    final result = DiseaseAnalysisService.fromNotebookDraft().analyze(
      prediction: const ScanPrediction(
        label: ConditionLabel.blast,
        confidence: 0.8,
        isSimulated: false,
      ),
      observations: [observation(id: 'G05', confidence: 1)],
      fuzzyInputs: const FuzzyInputs(
        severityPercent: 50,
        daysAfterTransplant: 0,
        relativeHumidityPercent: 50,
      ),
      diseaseDetail: details.getDetail(ConditionLabel.blast),
    );

    expect(result.diagnosisCertain, isTrue);
    expect(result.chemicalActionLevel, ChemicalActionLevel.recommended);
  });

  test('service sehat hanya menyediakan materi perawatan', () {
    final result = DiseaseAnalysisService.fromNotebookDraft().analyze(
      prediction: const ScanPrediction(
        label: ConditionLabel.healthy,
        confidence: 0.9,
        isSimulated: false,
      ),
      observations: const [],
      fuzzyInputs: const FuzzyInputs(),
      diseaseDetail: details.getDetail(ConditionLabel.healthy),
    );

    expect(result.certaintyResult.status, CertaintyStatus.notCalculated);
    expect(result.recommendations.single.category, 'Perawatan tanaman sehat');
    expect(result.recommendations.single.content, contains('pemantauan rutin'));
  });
}
