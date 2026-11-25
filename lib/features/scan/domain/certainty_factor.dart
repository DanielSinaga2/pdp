import '../../knowledge/domain/condition_label.dart';

class SymptomObservation {
  SymptomObservation({
    required this.symptomId,
    required this.symptomName,
    required this.userConfidence,
    this.isEnvironmental = false,
  }) {
    if (symptomId.trim().isEmpty || symptomName.trim().isEmpty) {
      throw ArgumentError('Evidence identity and name must not be empty.');
    }
    if (!userConfidence.isFinite || userConfidence < 0 || userConfidence > 1) {
      throw ArgumentError.value(userConfidence, 'userConfidence');
    }
  }

  final String symptomId;
  final String symptomName;
  final double userConfidence;
  final bool isEnvironmental;
}

class ExpertRule {
  ExpertRule({
    required this.symptomId,
    required this.condition,
    required this.expertWeight,
    required this.symptomName,
    this.isEnvironmental = false,
  }) {
    if (symptomId.trim().isEmpty || symptomName.trim().isEmpty) {
      throw ArgumentError('Expert rule identity and name must not be empty.');
    }
    if (!expertWeight.isFinite || expertWeight < -1 || expertWeight > 1) {
      throw ArgumentError.value(expertWeight, 'expertWeight');
    }
  }

  final String symptomId;
  final String symptomName;
  final ConditionLabel condition;

  /// Signed CF pakar from the notebook; negative values disconfirm a disease.
  final double expertWeight;
  final bool isEnvironmental;
}

class SymptomEvidence {
  const SymptomEvidence({
    required this.symptomId,
    required this.symptomName,
    required this.condition,
    required this.expertWeight,
    required this.userConfidence,
    required this.cfValue,
    required this.isEnvironmental,
  });

  final String symptomId;
  final String symptomName;
  final ConditionLabel condition;
  final double expertWeight;
  final double userConfidence;
  final double cfValue;
  final bool isEnvironmental;
}

enum CertaintyStatus { notCalculated, calculated, incompleteExpertRules }

class CertaintyCalculationStep {
  const CertaintyCalculationStep({
    required this.positiveEvidence,
    required this.negativeEvidence,
    required this.combined,
  });

  final double positiveEvidence;
  final double negativeEvidence;
  final double combined;
}

class CertaintyResult {
  const CertaintyResult({
    required this.condition,
    required this.status,
    required this.evidence,
    required this.steps,
    required this.missingRuleIds,
    this.score,
  });

  final ConditionLabel condition;
  final CertaintyStatus status;
  final double? score;
  final List<SymptomEvidence> evidence;
  final List<CertaintyCalculationStep> steps;
  final List<String> missingRuleIds;

  bool get isCalculated => status == CertaintyStatus.calculated;
}

class CertaintyFactorCalculator {
  const CertaintyFactorCalculator();

  CertaintyResult calculate({
    required ConditionLabel condition,
    required Iterable<SymptomObservation> observations,
    required Iterable<ExpertRule> rules,
  }) {
    final allRules = rules.toList();
    final rulesById = <String, List<ExpertRule>>{};
    for (final rule in allRules) {
      if (rule.condition == condition) {
        rulesById.putIfAbsent(rule.symptomId, () => []).add(rule);
      }
    }

    final evidence = <SymptomEvidence>[];
    final missingRuleIds = <String>[];
    final rulesBySource = <String, List<ExpertRule>>{};
    for (final rule in allRules) {
      rulesBySource.putIfAbsent(rule.symptomId, () => []).add(rule);
    }

    for (final observation in observations) {
      if (observation.userConfidence == 0) continue;
      final matchingRules = rulesById[observation.symptomId];
      if (matchingRules == null) {
        if (!rulesBySource.containsKey(observation.symptomId)) {
          missingRuleIds.add(observation.symptomId);
        }
        continue;
      }
      for (final rule in matchingRules) {
        evidence.add(
          SymptomEvidence(
            symptomId: observation.symptomId,
            symptomName: observation.symptomName,
            condition: condition,
            expertWeight: rule.expertWeight,
            userConfidence: observation.userConfidence,
            cfValue: rule.expertWeight * observation.userConfidence,
            isEnvironmental: observation.isEnvironmental,
          ),
        );
      }
    }

    if (evidence.isEmpty || missingRuleIds.isNotEmpty) {
      return CertaintyResult(
        condition: condition,
        status: missingRuleIds.isNotEmpty
            ? CertaintyStatus.incompleteExpertRules
            : CertaintyStatus.notCalculated,
        evidence: List.unmodifiable(evidence),
        steps: const [],
        missingRuleIds: List.unmodifiable(missingRuleIds),
      );
    }

    final positive = evidence
        .map((item) => item.cfValue)
        .where((value) => value > 0)
        .toList();
    final negative = evidence
        .map((item) => item.cfValue)
        .where((value) => value < 0)
        .map((value) => -value)
        .toList();
    final combinedPositive = _combineSameSign(positive);
    final combinedNegative = _combineSameSign(negative);
    final denominator =
        1 -
        (combinedPositive < combinedNegative
            ? combinedPositive
            : combinedNegative);
    final score = denominator > 1e-9
        ? (combinedPositive - combinedNegative) / denominator
        : 0.0;

    return CertaintyResult(
      condition: condition,
      status: CertaintyStatus.calculated,
      score: score,
      evidence: List.unmodifiable(evidence),
      steps: [
        CertaintyCalculationStep(
          positiveEvidence: combinedPositive,
          negativeEvidence: combinedNegative,
          combined: score,
        ),
      ],
      missingRuleIds: const [],
    );
  }

  double _combineSameSign(List<double> values) {
    if (values.isEmpty) return 0;
    var remaining = 1.0;
    for (final value in values) {
      remaining *= 1 - value.abs();
    }
    return 1 - remaining;
  }
}

class NotebookExpertRules {
  const NotebookExpertRules._();

  static const userConfidenceLevels = <double>[0, 0.4, 0.6, 0.8, 1];

  static final List<ExpertRule> rules = List.unmodifiable([
    ..._symptomRules,
    ..._environmentRules,
  ]);

  static final _symptomRules = <ExpertRule>[
    ExpertRule(
      symptomId: 'G01',
      symptomName: 'Garis basah/kekuningan memanjang di tepi daun',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.8,
    ),
    ExpertRule(
      symptomId: 'G02',
      symptomName: 'Tepi/ujung daun mengering keabu-abuan seperti terbakar',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.6,
    ),
    ExpertRule(
      symptomId: 'G03',
      symptomName: 'Tetesan lendir kuning keruh pada daun sakit',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.7,
    ),
    ExpertRule(
      symptomId: 'G04',
      symptomName: 'Daun muda layu menggulung dan mati (kresek)',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.7,
    ),
    ExpertRule(
      symptomId: 'G05',
      symptomName: 'Bercak berbentuk belah ketupat',
      condition: ConditionLabel.blast,
      expertWeight: 0.8,
    ),
    ExpertRule(
      symptomId: 'G05',
      symptomName: 'Bercak berbentuk belah ketupat',
      condition: ConditionLabel.brownSpot,
      expertWeight: -0.3,
    ),
    ExpertRule(
      symptomId: 'G06',
      symptomName: 'Bercak berpusat abu-abu keputihan dengan tepi coklat',
      condition: ConditionLabel.blast,
      expertWeight: 0.8,
    ),
    ExpertRule(
      symptomId: 'G07',
      symptomName: 'Leher malai busuk coklat/patah, malai hampa',
      condition: ConditionLabel.blast,
      expertWeight: 0.7,
    ),
    ExpertRule(
      symptomId: 'G08',
      symptomName: 'Bercak bulat-oval coklat kecil tersebar di daun',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.7,
    ),
    ExpertRule(
      symptomId: 'G09',
      symptomName: 'Bercak dikelilingi lingkaran (halo) kuning',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.8,
    ),
    ExpertRule(
      symptomId: 'G09',
      symptomName: 'Bercak dikelilingi lingkaran (halo) kuning',
      condition: ConditionLabel.blast,
      expertWeight: -0.2,
    ),
    ExpertRule(
      symptomId: 'G10',
      symptomName: 'Tanah kurang subur / tanaman tampak kurang hara',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.5,
    ),
    ExpertRule(
      symptomId: 'G11',
      symptomName: 'Tanaman sempat kekurangan air (lahan retak/kering)',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.3,
    ),
    ExpertRule(
      symptomId: 'G12',
      symptomName: 'Daun menguning-oranye dimulai dari ujung daun',
      condition: ConditionLabel.tungro,
      expertWeight: 0.7,
    ),
    ExpertRule(
      symptomId: 'G13',
      symptomName: 'Tanaman kerdil dan anakan sedikit',
      condition: ConditionLabel.tungro,
      expertWeight: 0.8,
    ),
    ExpertRule(
      symptomId: 'G14',
      symptomName: 'Ada wereng hijau di rumpun/lahan sekitar',
      condition: ConditionLabel.tungro,
      expertWeight: 0.6,
    ),
    ExpertRule(
      symptomId: 'G15',
      symptomName: 'Daun menguning merata tanpa bercak',
      condition: ConditionLabel.tungro,
      expertWeight: 0.5,
    ),
    ExpertRule(
      symptomId: 'G15',
      symptomName: 'Daun menguning merata tanpa bercak',
      condition: ConditionLabel.brownSpot,
      expertWeight: -0.3,
    ),
    ExpertRule(
      symptomId: 'G15',
      symptomName: 'Daun menguning merata tanpa bercak',
      condition: ConditionLabel.blast,
      expertWeight: -0.3,
    ),
    ExpertRule(
      symptomId: 'G16',
      symptomName: 'Baru-baru ini memberi Urea dosis tinggi',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.3,
    ),
    ExpertRule(
      symptomId: 'G16',
      symptomName: 'Baru-baru ini memberi Urea dosis tinggi',
      condition: ConditionLabel.blast,
      expertWeight: 0.4,
    ),
  ];

  static final _environmentRules = <ExpertRule>[
    ExpertRule(
      symptomId: 'E01',
      symptomName: 'Kelembapan udara tinggi',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.4,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E01',
      symptomName: 'Kelembapan udara tinggi',
      condition: ConditionLabel.blast,
      expertWeight: 0.5,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E02',
      symptomName: 'Hujan lebat 7 hari terakhir',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.4,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E02',
      symptomName: 'Hujan lebat 7 hari terakhir',
      condition: ConditionLabel.blast,
      expertWeight: 0.2,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E03',
      symptomName: 'Suhu sejuk (malam dingin)',
      condition: ConditionLabel.blast,
      expertWeight: 0.4,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E04',
      symptomName: 'Cuaca kering',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.4,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E05',
      symptomName: 'Umur tanaman masih awal',
      condition: ConditionLabel.tungro,
      expertWeight: 0.4,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E05',
      symptomName: 'Umur tanaman masih awal',
      condition: ConditionLabel.bacterialLeafBlight,
      expertWeight: 0.2,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E06',
      symptomName: 'Umur tanaman fase akhir',
      condition: ConditionLabel.brownSpot,
      expertWeight: 0.3,
      isEnvironmental: true,
    ),
    ExpertRule(
      symptomId: 'E06',
      symptomName: 'Umur tanaman fase akhir',
      condition: ConditionLabel.blast,
      expertWeight: 0.3,
      isEnvironmental: true,
    ),
  ];
}
