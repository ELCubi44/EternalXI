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

  /// Índice ordinal del nivel (Normal=0 … XI=4).
  int get stepIndex => ClashTechniqueLevel.values.indexOf(this);

  bool get isMax => this == ClashTechniqueLevel.xi;

  /// Etiqueta legible para UI (Normal, I, V, X, XI).
  String get displayLabel => switch (this) {
    ClashTechniqueLevel.normal => 'Normal',
    ClashTechniqueLevel.i => 'I',
    ClashTechniqueLevel.v => 'V',
    ClashTechniqueLevel.x => 'X',
    ClashTechniqueLevel.xi => 'XI',
  };

  static ClashTechniqueLevel fromStepIndex(int index) {
    final values = ClashTechniqueLevel.values;
    final clamped = index.clamp(0, values.length - 1);
    return values[clamped];
  }

  /// Avanza [steps] niveles sin superar XI.
  ClashTechniqueLevel advancedBy(int steps) {
    if (steps <= 0 || isMax) {
      return this;
    }
    return fromStepIndex(stepIndex + steps);
  }

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
