/// Tipo de supertécnica Clash. No existe técnica de pase.
enum ClashTechniqueType {
  save,
  defense,
  dribble,
  shot;

  String toJson() => name;

  static ClashTechniqueType fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'save' || 'parada' => ClashTechniqueType.save,
      'defense' || 'defensa' => ClashTechniqueType.defense,
      'dribble' || 'regate' => ClashTechniqueType.dribble,
      'shot' || 'tiro' => ClashTechniqueType.shot,
      _ => throw FormatException('Tipo de supertécnica desconocido: $value'),
    };
  }
}
