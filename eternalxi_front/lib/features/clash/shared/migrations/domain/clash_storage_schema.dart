/// Versión global del esquema local de Clash (Fase 56).
abstract final class ClashStorageSchema {
  /// Versión actual soportada por la app.
  static const int currentVersion = 1;

  /// Instalaciones previas a Fase 56 (sin `clash_schema_version`).
  static const int legacyUntrackedVersion = 0;
}
