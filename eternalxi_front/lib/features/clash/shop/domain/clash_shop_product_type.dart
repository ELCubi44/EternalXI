/// Tipo de recompensa concedida por un producto de tienda (Fase 27).
enum ClashShopProductType {
  expMaterial,
  techniqueBook,
  evolutionMaterial,
  ticket;

  static ClashShopProductType? fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'expMaterial' => ClashShopProductType.expMaterial,
      'techniqueBook' => ClashShopProductType.techniqueBook,
      'evolutionMaterial' => ClashShopProductType.evolutionMaterial,
      'ticket' => ClashShopProductType.ticket,
      _ => null,
    };
  }

  String toJson() => name;
}
