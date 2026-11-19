enum ConditionLabel {
  bacterialLeafBlight('bacterial_leaf_blight'),
  blast('blast'),
  brownSpot('brown_spot'),
  tungro('tungro'),
  healthy('healthy');

  const ConditionLabel(this.code);

  final String code;
}
