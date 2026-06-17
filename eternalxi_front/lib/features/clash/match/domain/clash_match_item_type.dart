/// Tipo de objeto usable en el descanso de partido Clash.
enum ClashMatchItemType {
  recoverPtSingle,
  recoverPtTriple,
  recoverPtAllSmall,
  recoverStaminaSingle,
  recoverStaminaTriple,
  recoverStaminaAllSmall;

  bool get isPtRecovery => switch (this) {
    recoverPtSingle || recoverPtTriple || recoverPtAllSmall => true,
    _ => false,
  };

  bool get isStaminaRecovery => !isPtRecovery;

  bool get requiresPlayerSelection => switch (this) {
    recoverPtSingle ||
    recoverPtTriple ||
    recoverStaminaSingle ||
    recoverStaminaTriple => true,
    recoverPtAllSmall || recoverStaminaAllSmall => false,
  };

  int get maxTargets => switch (this) {
    recoverPtSingle || recoverStaminaSingle => 1,
    recoverPtTriple || recoverStaminaTriple => 3,
    recoverPtAllSmall || recoverStaminaAllSmall => 7,
  };

  String toJson() => name;

  static ClashMatchItemType fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'recoverPtSingle' => ClashMatchItemType.recoverPtSingle,
      'recoverPtTriple' => ClashMatchItemType.recoverPtTriple,
      'recoverPtAllSmall' => ClashMatchItemType.recoverPtAllSmall,
      'recoverStaminaSingle' => ClashMatchItemType.recoverStaminaSingle,
      'recoverStaminaTriple' => ClashMatchItemType.recoverStaminaTriple,
      'recoverStaminaAllSmall' => ClashMatchItemType.recoverStaminaAllSmall,
      _ => throw FormatException(
        'Tipo de objeto de partido desconocido: $value',
      ),
    };
  }
}
