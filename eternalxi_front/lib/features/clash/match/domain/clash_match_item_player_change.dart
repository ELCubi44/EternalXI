/// Cambio aplicado a un jugador al usar un objeto de partido.
class ClashMatchItemPlayerChange {
  const ClashMatchItemPlayerChange({
    required this.playerIndex,
    required this.label,
    this.beforePt,
    this.afterPt,
    this.beforeStamina,
    this.afterStamina,
  });

  final int playerIndex;
  final String label;
  final int? beforePt;
  final int? afterPt;
  final int? beforeStamina;
  final int? afterStamina;

  int get ptDelta =>
      beforePt != null && afterPt != null ? afterPt! - beforePt! : 0;

  int get staminaDelta => beforeStamina != null && afterStamina != null
      ? afterStamina! - beforeStamina!
      : 0;
}
