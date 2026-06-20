import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';

/// Estado visual del indicador informativo de sync (Fase 78).
enum ClashSyncStatusBadgeKind {
  notPrepared,
  synced,
  pendingLocal,
  conflict,
  error,
  backupAvailable,
}

/// Resuelve el estado del badge desde metadata local persistida.
class ClashSyncStatusBadgePresentation {
  const ClashSyncStatusBadgePresentation._();

  static ClashSyncStatusBadgeKind resolve(ClashSyncMetadata metadata) {
    final status = metadata.lastStatusEnum;

    if (status == ClashSyncStatus.conflict) {
      return ClashSyncStatusBadgeKind.conflict;
    }
    if (_isErrorState(metadata)) {
      return ClashSyncStatusBadgeKind.error;
    }
    if (metadata.hasLocalBackup) {
      return ClashSyncStatusBadgeKind.backupAvailable;
    }
    if (metadata.hasPendingRemoteSnapshot) {
      return ClashSyncStatusBadgeKind.pendingLocal;
    }
    if (_isSynced(metadata)) {
      return ClashSyncStatusBadgeKind.synced;
    }
    if (_hasKnownRemoteSave(metadata)) {
      return ClashSyncStatusBadgeKind.pendingLocal;
    }
    return ClashSyncStatusBadgeKind.notPrepared;
  }

  static bool _hasKnownRemoteSave(ClashSyncMetadata metadata) =>
      metadata.knownServerRevision != null && metadata.knownServerRevision! > 0;

  static bool _isSynced(ClashSyncMetadata metadata) =>
      _hasKnownRemoteSave(metadata) &&
      metadata.lastSuccessfulSyncAt != null &&
      metadata.lastStatusEnum == ClashSyncStatus.success &&
      !metadata.hasPendingRemoteSnapshot;

  static bool _isErrorState(ClashSyncMetadata metadata) {
    if (metadata.lastErrorCode == 'unauthorized') {
      return true;
    }
    final status = metadata.lastStatusEnum;
    if (status == ClashSyncStatus.unavailable) {
      return true;
    }
    if (metadata.lastErrorCode != null &&
        status != ClashSyncStatus.success &&
        status != ClashSyncStatus.notFound) {
      return true;
    }
    return false;
  }
}
