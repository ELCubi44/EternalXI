/// Tipos de objetivo de un nivel match Clash (Fase 16+).
enum ClashMatchObjectiveType {
  winMatch,
  cleanSheet,
  scoreWithShotTechnique,
  winDribbleDuel,
  winDefensiveDuel,
  saveWithSaveTechnique,
  scoreWithStyleAdvantage,
  scoreWithSameStyleTechnique,
  winDuelWithStyleDisadvantage;

  String toJson() => name;

  static ClashMatchObjectiveType fromJson(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      throw FormatException('Tipo de objetivo match ausente');
    }
    return ClashMatchObjectiveType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => throw FormatException('Tipo de objetivo desconocido: $raw'),
    );
  }
}
