/// Rareza de una carta Clash.
enum ClashRarity {
  n,
  r,
  sr,
  lr,
  xi;

  /// Nivel máximo alcanzable para esta rareza.
  int get maxLevel => switch (this) {
    ClashRarity.n => 60,
    ClashRarity.r => 80,
    ClashRarity.sr => 100,
    ClashRarity.lr => 120,
    ClashRarity.xi => 120,
  };

  /// Número máximo de supertécnicas activas (sin contar pasiva XI).
  int get maxSuperTechniques => switch (this) {
    ClashRarity.n => 1,
    ClashRarity.r => 2,
    ClashRarity.sr => 3,
    ClashRarity.lr => 4,
    ClashRarity.xi => 4,
  };

  /// Solo XI puede tener pasiva según la regla inicial.
  bool get allowsPassive => this == ClashRarity.xi;

  /// SR, LR y XI pueden tener árbol de duplicados.
  bool get hasDuplicateTree =>
      this == ClashRarity.sr ||
      this == ClashRarity.lr ||
      this == ClashRarity.xi;

  /// LR y XI no se obtienen por evolución.
  bool get obtainableByEvolution =>
      this == ClashRarity.r || this == ClashRarity.sr;

  /// Destinos de evolución permitidos desde esta rareza.
  Set<ClashRarity> get evolutionTargets => switch (this) {
    ClashRarity.n => {ClashRarity.r, ClashRarity.sr},
    ClashRarity.r => {ClashRarity.sr},
    ClashRarity.sr || ClashRarity.lr || ClashRarity.xi => const {},
  };

  /// Indica si puede evolucionar a [target].
  bool canEvolveTo(ClashRarity target) => evolutionTargets.contains(target);

  String toJson() => name;

  static ClashRarity fromJson(Object? value) {
    final raw = value?.toString().trim().toLowerCase();
    return switch (raw) {
      'n' || 'normal' => ClashRarity.n,
      'r' || 'raro' => ClashRarity.r,
      'sr' || 'super_raro' || 'superraro' => ClashRarity.sr,
      'lr' || 'legendario' => ClashRarity.lr,
      'xi' || 'eterno' => ClashRarity.xi,
      _ => throw FormatException('Rareza Clash desconocida: $value'),
    };
  }
}
