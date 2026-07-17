/// Estilo de juego de una carta Clash.
enum ClashPlayerStyle {
  picaro,
  potente,
  agil,
  preciso,
  valiente;

  /// Nombre visible en español para UI y dominio.
  String get displayNameEs => switch (this) {
    ClashPlayerStyle.picaro => 'Pícaro',
    ClashPlayerStyle.potente => 'Potente',
    ClashPlayerStyle.agil => 'Ágil',
    ClashPlayerStyle.preciso => 'Preciso',
    ClashPlayerStyle.valiente => 'Valiente',
  };

  /// Emoticono corto para filtros (sin texto).
  String get emoji => switch (this) {
    ClashPlayerStyle.picaro => '🎭',
    ClashPlayerStyle.potente => '💪',
    ClashPlayerStyle.agil => '⚡',
    ClashPlayerStyle.preciso => '🎯',
    ClashPlayerStyle.valiente => '🦁',
  };

  String toJson() => name;

  static ClashPlayerStyle fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'picaro' || 'pícaro' => ClashPlayerStyle.picaro,
      'potente' => ClashPlayerStyle.potente,
      'agil' || 'ágil' => ClashPlayerStyle.agil,
      'preciso' => ClashPlayerStyle.preciso,
      'valiente' => ClashPlayerStyle.valiente,
      _ => throw FormatException('Estilo Clash desconocido: $value'),
    };
  }
}

/// Resultado de comparar dos estilos en la rueda de ventajas.
enum ClashStyleMatchup { advantage, neutral, disadvantage }

/// Determina la relación de [attacker] frente a [defender] en duelos.
///
/// Rueda: Pícaro > Potente > Valiente > Preciso > Ágil > Pícaro.
ClashStyleMatchup compareClashStyles(
  ClashPlayerStyle attacker,
  ClashPlayerStyle defender,
) {
  if (attacker == defender) {
    return ClashStyleMatchup.neutral;
  }

  const beats = <ClashPlayerStyle, ClashPlayerStyle>{
    ClashPlayerStyle.picaro: ClashPlayerStyle.potente,
    ClashPlayerStyle.potente: ClashPlayerStyle.valiente,
    ClashPlayerStyle.valiente: ClashPlayerStyle.preciso,
    ClashPlayerStyle.preciso: ClashPlayerStyle.agil,
    ClashPlayerStyle.agil: ClashPlayerStyle.picaro,
  };

  if (beats[attacker] == defender) {
    return ClashStyleMatchup.advantage;
  }
  if (beats[defender] == attacker) {
    return ClashStyleMatchup.disadvantage;
  }
  return ClashStyleMatchup.neutral;
}
