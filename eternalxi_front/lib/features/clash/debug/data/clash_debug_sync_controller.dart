import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter/foundation.dart';

/// Estado en memoria del panel manual de sync online en diagnóstico (Fase 72–75).
class ClashDebugSyncController extends ChangeNotifier {
  ClashDebugSyncController({
    required this.coordinator,
    this.applier,
    this.backupStore,
    this.isAuthenticated,
  });

  final ClashSyncCoordinator coordinator;
  final ClashSyncSnapshotApplier? applier;
  final ClashSyncLocalBackupStore? backupStore;
  final Future<bool> Function()? isAuthenticated;

  ClashSyncOperationResult? lastResult;
  ClashSyncOperationResult? lastValidateResult;
  ClashSyncOperationResult? lastPullResult;
  ClashSyncOperationResult? lastPushResult;
  ClashSyncApplyResult? lastApplyResult;
  ClashSyncApplyResult? lastRestoreResult;
  ClashSyncSnapshot? pendingRemoteSnapshot;
  int? knownServerRevision;
  bool busy = false;
  bool authRequired = false;

  bool get hasPendingRemoteSnapshot => pendingRemoteSnapshot != null;

  bool get hasLocalBackup => backupStore?.read() != null;

  bool get hasKnownRemoteSave =>
      knownServerRevision != null && knownServerRevision! > 0;

  bool get canApplyPendingRemote =>
      pendingRemoteSnapshot != null &&
      lastPullResult?.isSuccess == true &&
      applier != null;

  Future<void> validateLocal() async {
    if (!await _ensureAuthenticated()) {
      return;
    }
    await _run(() => coordinator.validateLocalSnapshotOnly());
  }

  Future<void> pullRemote() async {
    if (!await _ensureAuthenticated()) {
      return;
    }
    await _run(() async {
      final result = await coordinator.pullRemoteSnapshot();
      _rememberRevision(result);
      if (result.isSuccess && result.snapshot != null) {
        pendingRemoteSnapshot = result.snapshot;
      }
      if (result.isNotFound) {
        pendingRemoteSnapshot = null;
      }
      return result;
    });
  }

  /// Comprueba si subir pisaría una partida remota existente (puede hacer GET).
  Future<bool> willOverwriteRemoteSave() async {
    if (hasKnownRemoteSave) {
      return true;
    }
    if (!await _ensureAuthenticated()) {
      return false;
    }
    final probe = await coordinator.pullRemoteSnapshot();
    _recordOperationResult(probe);
    _rememberRevision(probe);
    if (probe.isSuccess && probe.snapshot != null) {
      pendingRemoteSnapshot = probe.snapshot;
    }
    notifyListeners();
    return probe.isSuccess;
  }

  /// Sube el snapshot local validado. Requiere confirmación previa si remoto existe.
  Future<void> executePushLocal() async {
    if (!await _ensureAuthenticated()) {
      return;
    }
    await _run(() async {
      if (hasKnownRemoteSave) {
        final result = await coordinator.pushLocalSnapshot(
          expectedServerRevision: knownServerRevision,
        );
        _rememberRevision(result);
        return result;
      }

      final probe = await coordinator.pullRemoteSnapshot();
      _recordOperationResult(probe);
      _rememberRevision(probe);
      if (probe.isNotFound) {
        final created = await coordinator.pushLocalSnapshot();
        _rememberRevision(created);
        return created;
      }
      if (!probe.isSuccess) {
        return _asPushResult(probe);
      }

      if (probe.snapshot != null) {
        pendingRemoteSnapshot = probe.snapshot;
      }
      knownServerRevision = probe.serverRevision;
      final updated = await coordinator.pushLocalSnapshot(
        expectedServerRevision: knownServerRevision,
      );
      _rememberRevision(updated);
      return updated;
    });
  }

  /// Aplica el snapshot remoto pendiente. Requiere confirmación en UI antes de llamar.
  Future<ClashSyncApplyResult?> applyPendingRemote() async {
    final remote = pendingRemoteSnapshot;
    final snapshotApplier = applier;
    if (remote == null || snapshotApplier == null) {
      return null;
    }
    if (!await _ensureAuthenticated()) {
      return null;
    }

    authRequired = false;
    busy = true;
    notifyListeners();
    try {
      lastApplyResult = await snapshotApplier.applyRemoteSnapshot(
        remote,
        serverRevision: knownServerRevision,
      );
      return lastApplyResult;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _run(Future<ClashSyncOperationResult> Function() action) async {
    authRequired = false;
    busy = true;
    notifyListeners();
    try {
      final result = await action();
      _recordOperationResult(result);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _recordOperationResult(ClashSyncOperationResult result) {
    lastResult = result;
    switch (result.operation) {
      case ClashSyncOperation.validate:
        lastValidateResult = result;
      case ClashSyncOperation.pull:
        lastPullResult = result;
      case ClashSyncOperation.push:
        lastPushResult = result;
    }
  }

  Future<bool> _ensureAuthenticated() async {
    final check = isAuthenticated;
    if (check == null) {
      authRequired = false;
      return true;
    }
    final ok = await check();
    authRequired = !ok;
    if (!ok) {
      notifyListeners();
    }
    return ok;
  }

  void _rememberRevision(ClashSyncOperationResult result) {
    if (result.isSuccess && result.serverRevision != null) {
      knownServerRevision = result.serverRevision;
      return;
    }
    if (result.isConflict && result.conflict != null) {
      knownServerRevision = result.conflict!.actualRevision;
    }
  }

  ClashSyncOperationResult _asPushResult(ClashSyncOperationResult source) {
    return ClashSyncOperationResult(
      operation: ClashSyncOperation.push,
      status: source.status,
      snapshot: source.snapshot,
      validationResult: source.validationResult,
      serverRevision: source.serverRevision,
      conflict: source.conflict,
      message: source.message,
      errorCode: source.errorCode,
      startedAt: source.startedAt,
      completedAt: source.completedAt,
    );
  }

  bool get isUnauthorized =>
      lastResult?.errorCode == 'unauthorized' ||
      (lastResult?.status == ClashSyncStatus.unavailable &&
          lastResult?.errorCode == 'unauthorized');
}
