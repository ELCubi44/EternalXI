/// Estado del flujo de un duelo en curso.
enum ClashDuelStatus {
  /// Usuario elige acción ofensiva (regate/tiro).
  pendingUserChoice,

  /// Usuario elige defensor ante avance rival (varios candidatos).
  pendingUserDefenderSelection,

  /// Usuario elige defensa/parada; rival ya eligió ataque.
  pendingUserDefensiveChoice,

  resolved,
}
