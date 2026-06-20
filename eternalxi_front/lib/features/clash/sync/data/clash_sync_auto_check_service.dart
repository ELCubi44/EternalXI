import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';

/// Auto-check remoto opcional al abrir Clash (Fase 79).
///
/// Solo GET/pull cuando el flag está activo. No aplica, sube ni crea saves.
class ClashSyncAutoCheckService {
  const ClashSyncAutoCheckService({
    required this.coordinator,
    required this.settingsStorage,
    required this.metadataStorage,
    this.backupStore,
    this.minPullInterval = pullThrottleInterval,
    this.now,
  });

  /// Mínimo entre pulls automáticos consecutivos.
  static const pullThrottleInterval = Duration(minutes: 5);

  final ClashSyncCoordinator coordinator;
  final ClashSyncSettingsStorage settingsStorage;
  final ClashSyncMetadataStorage metadataStorage;
  final ClashSyncLocalBackupStore? backupStore;
  final Duration minPullInterval;
  final DateTime Function()? now;

  /// Ejecuta pull remoto si el ajuste está activo. Devuelve `null` si está off o throttled.
  Future<ClashSyncOperationResult?> runIfEnabled() async {
    if (!settingsStorage.load().autoCheckEnabledOnClashOpen) {
      return null;
    }

    final currentMetadata = metadataStorage.load();
    if (_isThrottled(currentMetadata.lastPullAt)) {
      return null;
    }

    final result = await coordinator.pullRemoteSnapshot();
    final hasPending = result.isSuccess && result.snapshot != null;
    final hasBackup =
        backupStore?.read() != null || currentMetadata.hasLocalBackup;

    await metadataStorage.updateAfterOperation(
      result,
      hasPendingRemoteSnapshot: hasPending,
      hasLocalBackup: hasBackup,
    );

    return result;
  }

  bool _isThrottled(DateTime? lastPullAt) {
    if (lastPullAt == null) {
      return false;
    }
    final clock = now ?? DateTime.now;
    return clock().toUtc().difference(lastPullAt.toUtc()) < minPullInterval;
  }
}
