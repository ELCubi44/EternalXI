/// Categoría de un ítem del inventario central Clash (Fase 22).
enum ClashInventoryCategory {
  exp,
  technique,
  evolution,
  match,
  tickets;

  String get l10nKey => switch (this) {
    ClashInventoryCategory.exp => 'clashInventoryExp',
    ClashInventoryCategory.technique => 'clashInventoryTechnique',
    ClashInventoryCategory.evolution => 'clashInventoryEvolution',
    ClashInventoryCategory.match => 'clashInventoryMatch',
    ClashInventoryCategory.tickets => 'clashInventoryTickets',
  };
}

/// Filtro de la pantalla de inventario (incluye vista combinada).
enum ClashInventoryFilter {
  all,
  exp,
  technique,
  evolution,
  match,
  tickets;

  ClashInventoryCategory? get category => switch (this) {
    ClashInventoryFilter.all => null,
    ClashInventoryFilter.exp => ClashInventoryCategory.exp,
    ClashInventoryFilter.technique => ClashInventoryCategory.technique,
    ClashInventoryFilter.evolution => ClashInventoryCategory.evolution,
    ClashInventoryFilter.match => ClashInventoryCategory.match,
    ClashInventoryFilter.tickets => ClashInventoryCategory.tickets,
  };
}
