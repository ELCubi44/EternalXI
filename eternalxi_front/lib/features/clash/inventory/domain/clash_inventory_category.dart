/// Categoría de un ítem del inventario central Clash (Fase 22).
enum ClashInventoryCategory {
  exp,
  technique,
  evolution,
  match;

  String get l10nKey => switch (this) {
    ClashInventoryCategory.exp => 'clashInventoryExp',
    ClashInventoryCategory.technique => 'clashInventoryTechnique',
    ClashInventoryCategory.evolution => 'clashInventoryEvolution',
    ClashInventoryCategory.match => 'clashInventoryMatch',
  };
}

/// Filtro de la pantalla de inventario (incluye vista combinada).
enum ClashInventoryFilter {
  all,
  exp,
  technique,
  evolution,
  match;

  ClashInventoryCategory? get category => switch (this) {
    ClashInventoryFilter.all => null,
    ClashInventoryFilter.exp => ClashInventoryCategory.exp,
    ClashInventoryFilter.technique => ClashInventoryCategory.technique,
    ClashInventoryFilter.evolution => ClashInventoryCategory.evolution,
    ClashInventoryFilter.match => ClashInventoryCategory.match,
  };
}
