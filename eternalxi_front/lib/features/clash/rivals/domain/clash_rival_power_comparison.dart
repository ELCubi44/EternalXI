/// Estado de comparativa de potencia propia vs rival/recomendada (Fase 43).
enum ClashRivalPowerMatchupStatus {
  clearAdvantage,
  even,
  disadvantage,
  veryHard,
}

/// Umbrales de aviso en preparación de partido (solo UI, no bloquea jugar).
class ClashRivalPowerComparison {
  const ClashRivalPowerComparison._();

  static const clearAdvantageMargin = 30;
  static const evenMargin = 15;
  static const disadvantageMargin = 40;

  static ClashRivalPowerMatchupStatus evaluate({
    required int ownPower,
    required int referencePower,
  }) {
    if (ownPower >= referencePower + clearAdvantageMargin) {
      return ClashRivalPowerMatchupStatus.clearAdvantage;
    }
    if (ownPower >= referencePower - evenMargin) {
      return ClashRivalPowerMatchupStatus.even;
    }
    if (ownPower >= referencePower - disadvantageMargin) {
      return ClashRivalPowerMatchupStatus.disadvantage;
    }
    return ClashRivalPowerMatchupStatus.veryHard;
  }

  static int difference(int ownPower, int referencePower) =>
      ownPower - referencePower;
}
