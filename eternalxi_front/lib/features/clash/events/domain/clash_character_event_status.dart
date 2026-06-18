/// Disponibilidad local de un evento de personaje Clash (Fase 33).
enum ClashCharacterEventAvailability {
  available,
  locked,
  expired;

  static ClashCharacterEventAvailability fromJson(Object? value) {
    final raw = value?.toString().trim();
    return switch (raw) {
      'locked' => ClashCharacterEventAvailability.locked,
      'expired' => ClashCharacterEventAvailability.expired,
      _ => ClashCharacterEventAvailability.available,
    };
  }
}
