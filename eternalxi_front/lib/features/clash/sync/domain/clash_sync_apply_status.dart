/// Estado del resultado de aplicar un snapshot remoto localmente (Fase 73).
enum ClashSyncApplyStatus {
  success,
  validationFailed,
  backupFailed,
  applyFailed,
  unsupported,
}
