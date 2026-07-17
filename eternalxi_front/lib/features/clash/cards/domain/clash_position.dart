/// Posición táctica de una carta Clash (7 posiciones canónicas).
enum ClashPosition {
  goalkeeper,
  centreBack,
  fullBack,
  defensiveMidfielder,
  attackingMidfielder,
  winger,
  striker;

  /// Nombre visible en español.
  String get displayNameEs => switch (this) {
    ClashPosition.goalkeeper => 'Portero',
    ClashPosition.centreBack => 'Defensa central',
    ClashPosition.fullBack => 'Lateral',
    ClashPosition.defensiveMidfielder => 'Mediocentro defensivo',
    ClashPosition.attackingMidfielder => 'Mediocentro ofensivo',
    ClashPosition.winger => 'Extremo',
    ClashPosition.striker => 'Delantero',
  };

  /// Grupo táctico amplio (defensa / medio / delantero / portero).
  ClashPositionGroup get group => switch (this) {
    ClashPosition.goalkeeper => ClashPositionGroup.goalkeeper,
    ClashPosition.centreBack || ClashPosition.fullBack =>
      ClashPositionGroup.defense,
    ClashPosition.defensiveMidfielder || ClashPosition.attackingMidfielder =>
      ClashPositionGroup.midfield,
    ClashPosition.winger || ClashPosition.striker => ClashPositionGroup.attack,
  };

  String toJson() => name;

  static ClashPosition fromJson(Object? value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) {
      throw FormatException('Posición Clash obligatoria ausente');
    }

    final normalized = raw
        .replaceAll(' ', '')
        .replaceAll('_', '')
        .toLowerCase();

    return switch (normalized) {
      'goalkeeper' || 'portero' || 'gk' => ClashPosition.goalkeeper,
      'centreback' || 'defensacentral' || 'cb' => ClashPosition.centreBack,
      'fullback' || 'lateral' || 'fb' => ClashPosition.fullBack,
      'defensivemidfielder' ||
      'mediocentrodefensivo' ||
      'dm' => ClashPosition.defensiveMidfielder,
      'attackingmidfielder' ||
      'mediocentroofensivo' ||
      'am' => ClashPosition.attackingMidfielder,
      'winger' || 'extremo' || 'wg' => ClashPosition.winger,
      'striker' || 'delantero' || 'st' => ClashPosition.striker,
      _ => ClashPosition.values.firstWhere(
        (p) => p.name.toLowerCase() == raw.toLowerCase(),
        orElse: () =>
            throw FormatException('Posición Clash desconocida: $value'),
      ),
    };
  }
}

/// Agrupación de posiciones para filtros de colección.
enum ClashPositionGroup {
  goalkeeper,
  defense,
  midfield,
  attack;

  String get displayNameEs => switch (this) {
    ClashPositionGroup.goalkeeper => 'Portero',
    ClashPositionGroup.defense => 'Defensas',
    ClashPositionGroup.midfield => 'Medios',
    ClashPositionGroup.attack => 'Delanteros',
  };

  String get emoji => switch (this) {
    ClashPositionGroup.goalkeeper => '🧤',
    ClashPositionGroup.defense => '🛡️',
    ClashPositionGroup.midfield => '🌀',
    ClashPositionGroup.attack => '⚽',
  };

  List<ClashPosition> get positions => switch (this) {
    ClashPositionGroup.goalkeeper => const [ClashPosition.goalkeeper],
    ClashPositionGroup.defense => const [
      ClashPosition.centreBack,
      ClashPosition.fullBack,
    ],
    ClashPositionGroup.midfield => const [
      ClashPosition.defensiveMidfielder,
      ClashPosition.attackingMidfielder,
    ],
    ClashPositionGroup.attack => const [
      ClashPosition.winger,
      ClashPosition.striker,
    ],
  };
}
