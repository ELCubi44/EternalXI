/// Fases del flujo �Momentos decisivos�.
enum ClashDecisiveMomentsPhase {
  /// Presentaci�n del momento (minuto + contexto).
  intro,

  /// El usuario elige carta de su plantilla.
  pickCard,

  /// Duelo activo: normal o supert�cnica.
  duel,

  /// Resultado del duelo + cr�nica.
  result,

  /// Partido terminado (5 momentos jugados).
  finished,
}
