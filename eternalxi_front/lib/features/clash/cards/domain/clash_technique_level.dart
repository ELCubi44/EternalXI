/// Nivel de mejora de una supertécnica.
enum ClashTechniqueLevel {
  normal,
  i,
  v,
  x,
  xi;

  /// Multiplicador provisional de potencia por nivel.
  ///
  /// Valores sujetos a balance futuro; el coste de PT no cambia al subir nivel.
  double get powerMultiplier => switch (this) {
    ClashTechniqueLevel.normal => 1.00,
    ClashTechniqueLevel.i => 1.05,
    ClashTechniqueLevel.v => 1.10,
    ClashTechniqueLevel.x => 1.15,
    ClashTechniqueLevel.xi => 1.20,
  };

  String toJson() => name;

  static ClashTechniqueLevel fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'normal' => ClashTechniqueLevel.normal,
      'i' => ClashTechniqueLevel.i,
      'v' => ClashTechniqueLevel.v,
      'x' => ClashTechniqueLevel.x,
      'xi' => ClashTechniqueLevel.xi,
      _ => throw FormatException('Nivel de supertécnica desconocido: $value'),
    };
  }
}
