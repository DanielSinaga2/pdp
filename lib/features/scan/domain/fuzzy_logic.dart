import '../../knowledge/domain/condition_label.dart';

class TrapezoidalMembership {
  TrapezoidalMembership({
    required this.a,
    required this.b,
    required this.c,
    required this.d,
  }) {
    if (![a, b, c, d].every((value) => value.isFinite) ||
        a > b ||
        b > c ||
        c > d) {
      throw ArgumentError(
        'Membership trapezoid must satisfy a <= b <= c <= d.',
      );
    }
  }

  final double a;
  final double b;
  final double c;
  final double d;

  double degree(double value) {
    if (!value.isFinite || value < a || value > d) return 0;
    if (b <= value && value <= c) return 1;
    if (value < b) return b > a ? (value - a) / (b - a) : 1;
    return d > c ? (d - value) / (d - c) : 1;
  }
}

class FuzzyInputs {
  const FuzzyInputs({
    this.severityPercent,
    this.daysAfterTransplant,
    this.relativeHumidityPercent,
    this.temperatureCelsius,
    this.rainfallLast7DaysMm,
  });

  final double? severityPercent;
  final double? daysAfterTransplant;
  final double? relativeHumidityPercent;
  final double? temperatureCelsius;
  final double? rainfallLast7DaysMm;

  bool get hasSugenoInputs =>
      severityPercent != null &&
      daysAfterTransplant != null &&
      relativeHumidityPercent != null;

  bool get hasEnvironmentalEvidenceInputs =>
      daysAfterTransplant != null &&
      relativeHumidityPercent != null &&
      temperatureCelsius != null &&
      rainfallLast7DaysMm != null;
}

class SugenoRule {
  SugenoRule({
    required this.id,
    required this.condition,
    required Map<String, String> antecedents,
    required this.ureaFactor,
    required this.kclFactor,
    required this.chemicalScore,
  }) : antecedents = Map.unmodifiable(antecedents) {
    if (!ureaFactor.isFinite ||
        !kclFactor.isFinite ||
        !chemicalScore.isFinite ||
        ureaFactor < 0 ||
        kclFactor < 0 ||
        chemicalScore < 0 ||
        chemicalScore > 1) {
      throw ArgumentError('Sugeno rule outputs are outside their valid range.');
    }
  }

  final String id;
  final ConditionLabel condition;
  final Map<String, String> antecedents;
  final double ureaFactor;
  final double kclFactor;
  final double chemicalScore;
}

class SugenoRuleActivation {
  const SugenoRuleActivation({
    required this.rule,
    required this.membershipStrength,
    required this.cfWeight,
    required this.weight,
  });

  final SugenoRule rule;
  final double membershipStrength;
  final double cfWeight;
  final double weight;
}

enum FuzzyStatus { notCalculated, calculated }

class FuzzyResult {
  const FuzzyResult({
    required this.status,
    required this.configurationValidated,
    required this.inputMemberships,
    required this.activeRules,
    this.ureaFactor,
    this.ureaFactorAfterGrowthStage,
    this.kclFactor,
    this.chemicalScore,
    this.message,
  });

  final FuzzyStatus status;
  final bool configurationValidated;
  final Map<String, Map<String, double>> inputMemberships;
  final List<SugenoRuleActivation> activeRules;
  final double? ureaFactor;
  final double? ureaFactorAfterGrowthStage;
  final double? kclFactor;
  final double? chemicalScore;
  final String? message;

  bool get isCalculated => status == FuzzyStatus.calculated;
}

class EnvironmentalEvidenceDegree {
  const EnvironmentalEvidenceDegree({
    required this.id,
    required this.name,
    required this.degree,
  });

  final String id;
  final String name;
  final double degree;
}

class FuzzyConfiguration {
  FuzzyConfiguration({
    required Map<String, Map<String, TrapezoidalMembership>> memberships,
    required List<SugenoRule> rules,
    required this.sourceNote,
    required this.configurationValidated,
  }) : memberships =
           Map<String, Map<String, TrapezoidalMembership>>.unmodifiable({
             for (final entry in memberships.entries)
               entry.key: Map<String, TrapezoidalMembership>.unmodifiable(
                 entry.value,
               ),
           }),
       rules = List.unmodifiable(rules);

  final Map<String, Map<String, TrapezoidalMembership>> memberships;
  final List<SugenoRule> rules;
  final String sourceNote;
  final bool configurationValidated;

  factory FuzzyConfiguration.fromNotebookDraft() => FuzzyConfiguration(
    memberships: {
      'severity': {
        'ringan': _trap(0, 0, 4, 10),
        'sedang': _trap(4, 12, 20, 30),
        'berat': _trap(20, 35, 100, 100),
      },
      'phase': {
        'awal': _trap(0, 0, 25, 45),
        'tengah': _trap(30, 45, 55, 70),
        'akhir': _trap(55, 75, 150, 150),
      },
      'humidity': {
        'rendah': _trap(0, 0, 60, 72),
        'sedang': _trap(62, 72, 80, 88),
        'tinggi': _trap(80, 90, 100, 100),
      },
      'temperature': {'sejuk': _trap(15, 15, 23, 27)},
      'rainfall': {
        'rendah': _trap(0, 0, 20, 50),
        'sedang': _trap(30, 70, 100, 150),
        'lebat': _trap(100, 150, 400, 400),
      },
    },
    rules: _notebookRules,
    sourceNote:
        'Rentang membership dan aturan Sugeno disalin dari notebook yang '
        'dibagikan; parameter tetap memerlukan validasi ahli pertanian.',
    configurationValidated: false,
  );

  static TrapezoidalMembership _trap(double a, double b, double c, double d) =>
      TrapezoidalMembership(a: a, b: b, c: c, d: d);

  static List<SugenoRule> get _notebookRules => [
    ..._rules(ConditionLabel.bacterialLeafBlight, [
      (conditions: {'severity': 'ringan'}, urea: 0.8, kcl: 1.3, chemical: 0.1),
      (conditions: {'severity': 'sedang'}, urea: 0.6, kcl: 1.4, chemical: 0.5),
      (conditions: {'severity': 'berat'}, urea: 0.4, kcl: 1.5, chemical: 0.9),
      (
        conditions: {'severity': 'sedang', 'humidity': 'tinggi'},
        urea: 0.5,
        kcl: 1.5,
        chemical: 0.8,
      ),
      (
        conditions: {'severity': 'berat', 'humidity': 'tinggi'},
        urea: 0.3,
        kcl: 1.5,
        chemical: 0.95,
      ),
      (conditions: {'phase': 'akhir'}, urea: 0, kcl: 1, chemical: 0.3),
    ]),
    ..._rules(ConditionLabel.blast, [
      (conditions: {'severity': 'ringan'}, urea: 0.8, kcl: 1.3, chemical: 0.2),
      (conditions: {'severity': 'sedang'}, urea: 0.6, kcl: 1.4, chemical: 0.6),
      (conditions: {'severity': 'berat'}, urea: 0.4, kcl: 1.5, chemical: 0.9),
      (
        conditions: {'severity': 'sedang', 'humidity': 'tinggi'},
        urea: 0.5,
        kcl: 1.5,
        chemical: 0.85,
      ),
      (
        conditions: {'severity': 'berat', 'humidity': 'tinggi'},
        urea: 0.3,
        kcl: 1.5,
        chemical: 0.95,
      ),
      (conditions: {'phase': 'akhir'}, urea: 0, kcl: 1, chemical: 0.5),
    ]),
    ..._rules(ConditionLabel.brownSpot, [
      (conditions: {'severity': 'ringan'}, urea: 1, kcl: 1.2, chemical: 0.1),
      (conditions: {'severity': 'sedang'}, urea: 1, kcl: 1.3, chemical: 0.5),
      (conditions: {'severity': 'berat'}, urea: 1, kcl: 1.5, chemical: 0.85),
      (
        conditions: {'severity': 'sedang', 'humidity': 'rendah'},
        urea: 1,
        kcl: 1.4,
        chemical: 0.5,
      ),
      (conditions: {'phase': 'akhir'}, urea: 0, kcl: 1, chemical: 0.2),
    ]),
    ..._rules(ConditionLabel.tungro, [
      (conditions: {'severity': 'ringan'}, urea: 0.9, kcl: 1.2, chemical: 0.3),
      (conditions: {'severity': 'sedang'}, urea: 0.8, kcl: 1.2, chemical: 0.6),
      (conditions: {'severity': 'berat'}, urea: 0.7, kcl: 1.2, chemical: 0.8),
      (
        conditions: {'phase': 'awal', 'severity': 'sedang'},
        urea: 0.8,
        kcl: 1.2,
        chemical: 0.7,
      ),
      (conditions: {'phase': 'akhir'}, urea: 0, kcl: 1, chemical: 0.1),
    ]),
  ];

  static List<SugenoRule> _rules(
    ConditionLabel condition,
    List<
      ({
        Map<String, String> conditions,
        double urea,
        double kcl,
        double chemical,
      })
    >
    values,
  ) => [
    for (var index = 0; index < values.length; index++)
      SugenoRule(
        id: '${condition.code}_${index + 1}',
        condition: condition,
        antecedents: values[index].conditions,
        ureaFactor: values[index].urea,
        kclFactor: values[index].kcl,
        chemicalScore: values[index].chemical,
      ),
  ];
}

class FuzzyLogicEngine {
  const FuzzyLogicEngine(this.configuration);

  final FuzzyConfiguration configuration;

  List<EnvironmentalEvidenceDegree> environmentalEvidence(FuzzyInputs input) {
    if (!input.hasEnvironmentalEvidenceInputs ||
        !_isNonNegative(input.daysAfterTransplant) ||
        !_isValid(input.relativeHumidityPercent, 0, 100) ||
        !_isFinite(input.temperatureCelsius) ||
        !_isNonNegative(input.rainfallLast7DaysMm)) {
      return const [];
    }
    final hst = input.daysAfterTransplant!;
    final humidity = input.relativeHumidityPercent!;
    final rain = input.rainfallLast7DaysMm!;
    final temperature = input.temperatureCelsius!;
    final dryDegree = _degree(
      'rainfall',
      'rendah',
      rain,
    ).clamp(0.0, 1.0).toDouble();
    final humidityHigh = _degree('humidity', 'tinggi', humidity);
    return [
      EnvironmentalEvidenceDegree(
        id: 'E01',
        name: 'Kelembapan udara tinggi',
        degree: humidityHigh,
      ),
      EnvironmentalEvidenceDegree(
        id: 'E02',
        name: 'Hujan lebat 7 hari terakhir',
        degree: _degree('rainfall', 'lebat', rain),
      ),
      EnvironmentalEvidenceDegree(
        id: 'E03',
        name: 'Suhu sejuk (malam dingin)',
        degree: _degree('temperature', 'sejuk', temperature),
      ),
      EnvironmentalEvidenceDegree(
        id: 'E04',
        name: 'Cuaca kering',
        degree: _min(dryDegree, 1 - humidityHigh),
      ),
      EnvironmentalEvidenceDegree(
        id: 'E05',
        name: 'Umur tanaman masih awal',
        degree: _degree('phase', 'awal', hst),
      ),
      EnvironmentalEvidenceDegree(
        id: 'E06',
        name: 'Umur tanaman fase akhir',
        degree: _degree('phase', 'akhir', hst),
      ),
    ];
  }

  FuzzyResult calculate(
    FuzzyInputs input,
    Map<ConditionLabel, double?> certaintyScores,
  ) {
    if (!input.hasSugenoInputs) {
      return _notCalculated('Lengkapi input keparahan, HST, dan RH.');
    }
    if (!_isValid(input.severityPercent, 0, 100) ||
        !_isNonNegative(input.daysAfterTransplant) ||
        !_isValid(input.relativeHumidityPercent, 0, 100)) {
      return _notCalculated('Input fuzzy berada di luar rentang notebook.');
    }
    if (configuration.rules.isEmpty) {
      return _notCalculated('Aturan Sugeno belum tersedia.');
    }

    final values = <String, double>{
      'severity': input.severityPercent!,
      'phase': input.daysAfterTransplant!,
      'humidity': input.relativeHumidityPercent!,
    };
    final inputMemberships = <String, Map<String, double>>{};
    for (final entry in values.entries) {
      final terms = configuration.memberships[entry.key];
      if (terms == null) {
        return _notCalculated('Membership ${entry.key} tidak tersedia.');
      }
      inputMemberships[entry.key] = {
        for (final term in terms.entries)
          term.key: term.value.degree(entry.value),
      };
    }

    var ureaNumerator = 0.0;
    var kclNumerator = 0.0;
    var chemicalNumerator = 0.0;
    var weightSum = 0.0;
    final activations = <SugenoRuleActivation>[];
    for (final rule in configuration.rules) {
      final cf = certaintyScores[rule.condition];
      if (cf == null || !cf.isFinite) continue;
      final cfWeight = (cf > 0 ? cf : 0).clamp(0.0, 1.0).toDouble();
      final sharpenedCf = cfWeight * cfWeight * cfWeight;
      if (sharpenedCf <= 0) continue;
      var membershipStrength = 1.0;
      var valid = true;
      for (final antecedent in rule.antecedents.entries) {
        final degree = inputMemberships[antecedent.key]?[antecedent.value];
        if (degree == null) {
          valid = false;
          break;
        }
        membershipStrength = _min(membershipStrength, degree);
      }
      if (!valid) continue;
      final weight = membershipStrength * sharpenedCf;
      if (weight <= 1e-9) continue;
      weightSum += weight;
      ureaNumerator += weight * rule.ureaFactor;
      kclNumerator += weight * rule.kclFactor;
      chemicalNumerator += weight * rule.chemicalScore;
      activations.add(
        SugenoRuleActivation(
          rule: rule,
          membershipStrength: membershipStrength,
          cfWeight: sharpenedCf,
          weight: weight,
        ),
      );
    }

    if (weightSum <= 0) {
      return _notCalculated('Tidak ada aturan Sugeno aktif dengan CF positif.');
    }
    activations.sort((first, second) => second.weight.compareTo(first.weight));
    final ureaFactor = ureaNumerator / weightSum;
    final hst = input.daysAfterTransplant!;
    return FuzzyResult(
      status: FuzzyStatus.calculated,
      configurationValidated: configuration.configurationValidated,
      inputMemberships: {
        for (final item in inputMemberships.entries)
          item.key: Map.unmodifiable(item.value),
      },
      activeRules: List.unmodifiable(activations),
      ureaFactor: ureaFactor,
      ureaFactorAfterGrowthStage: hst > 60 ? 0 : ureaFactor,
      kclFactor: kclNumerator / weightSum,
      chemicalScore: chemicalNumerator / weightSum,
      message: configuration.sourceNote,
    );
  }

  double _degree(String variable, String term, double value) {
    final membership = configuration.memberships[variable]?[term];
    if (membership == null) {
      throw StateError('Required notebook membership $variable.$term missing.');
    }
    return membership.degree(value);
  }

  bool _isValid(double? value, double minimum, double maximum) =>
      _isFinite(value) && value! >= minimum && value <= maximum;

  bool _isFinite(double? value) => value != null && value.isFinite;

  bool _isNonNegative(double? value) => _isFinite(value) && value! >= 0;

  double _min(double first, double second) => first < second ? first : second;

  FuzzyResult _notCalculated(String message) => FuzzyResult(
    status: FuzzyStatus.notCalculated,
    configurationValidated: configuration.configurationValidated,
    inputMemberships: const {},
    activeRules: const [],
    message: message,
  );
}
