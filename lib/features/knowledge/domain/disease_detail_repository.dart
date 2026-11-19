import 'condition_label.dart';

class DiseaseDetail {
  const DiseaseDetail({
    required this.name,
    this.symptoms,
    this.cause,
    this.management,
    this.needsReview = true,
  });

  final String name;
  final String? symptoms;
  final String? cause;
  final String? management;
  final bool needsReview;
}

abstract interface class DiseaseDetailRepository {
  DiseaseDetail getDetail(ConditionLabel label);
}
