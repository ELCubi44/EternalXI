/// Versión del contrato JSON de sincronización Clash (Fase 65).
///
/// Distinto de [ClashStorageSchema] / `clash_schema_version` en SharedPreferences,
/// que describe el esquema de persistencia local.
abstract final class ClashSyncContractVersion {
  static const int current = 1;
}
