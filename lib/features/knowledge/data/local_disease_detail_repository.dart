import '../domain/condition_label.dart';
import '../domain/disease_detail_repository.dart';

class LocalDiseaseDetailRepository implements DiseaseDetailRepository {
  const LocalDiseaseDetailRepository();

  @override
  DiseaseDetail getDetail(ConditionLabel label) => switch (label) {
    ConditionLabel.bacterialLeafBlight =>
      const DiseaseDetail(name: 'Hawar daun bakteri'),
    ConditionLabel.blast => const DiseaseDetail(name: 'Blast'),
    ConditionLabel.brownSpot => const DiseaseDetail(name: 'Bercak coklat'),
    ConditionLabel.tungro => const DiseaseDetail(name: 'Tungro'),
    ConditionLabel.healthy => const DiseaseDetail(name: 'Sehat'),
  };
}
