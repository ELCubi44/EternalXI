/// Tipo de noticia/avisos locales Clash (Fase 31).
enum ClashNewsType {
  update,
  event,
  banner,
  maintenance,
  gift;

  static ClashNewsType? fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'update' => ClashNewsType.update,
      'event' => ClashNewsType.event,
      'banner' => ClashNewsType.banner,
      'maintenance' => ClashNewsType.maintenance,
      'gift' => ClashNewsType.gift,
      _ => null,
    };
  }

  bool get isNotice =>
      this == ClashNewsType.maintenance || this == ClashNewsType.gift;
}
