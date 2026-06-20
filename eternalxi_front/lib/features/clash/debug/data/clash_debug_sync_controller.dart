import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_local_backup.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter/foundation.dart';

/// Estado del panel manual de sync online en diagnóstico (Fase 72–76).
class ClashDebugSyncController extends ChangeNotifier {
  ClashDebugSyncController({
    required this.coordinator,
    this.applier,
    this.backupStore,
    this.metadataStorage,
    this.isAuthenticated,
  }) : _metadata = metadataStorage?.load() ?? const ClashSyncMetadata() {
    knownServerRevision = _metadata.knownServerRevision;
  }

  final ClashSyncCoordinator coordinator;
  final ClashSyncSnapshotApplier? applier;
  final ClashSyncLocalBackupStore? backupStore;
  final ClashSyncMetadataStorage? metadataStorage;
  final Future<bool> Function()? isAuthenticated;

  ClashSyncMetadata _metadata;
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

  ClashSyncMetadata get metadata => _metadata;

  int? get effectiveKnownRevision =>
      knownServerRevision ?? _metadata.knownServerRevision;

  bool get hasPendingRemoteSnapshot =>
      pendingRemoteSnapshot != null || _metadata.hasPendingRemoteSnapshot;

  bool get hasInMemoryPendingRemoteSnapshot => pendingRemoteSnapshot != null;

  bool get hasLocalBackup =>
      backupStore?.read() != null || _metadata.hasLocalBackup;

  bool get hasKnownRemoteSave =>
      effectiveKnownRevision != null && effectiveKnownRevision! > 0;

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
    await _recordOperationResult(probe);
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
          expectedServerRevision: effectiveKnownRevision,
        );
        _rememberRevision(result);
        return result;
      }

      final probe = await coordinator.pullRemoteSnapshot();
      await _recordOperationResult(probe);
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
        serverRevision: effectiveKnownRevision,
      );
      await _persistApplyResult(lastApplyResult!, isRestore: false);
      return lastApplyResult;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  ClashSyncOperationResult? operationResultForDisplay(ClashSyncOperation op) {
    final memory = switch (op) {
      ClashSyncOperation.validate => lastValidateResult,
      ClashSyncOperation.pull => lastPullResult,
      ClashSyncOperation.push => lastPushResult,
    };
    if (memory != null) {
      return memory;
    }
    if (_metadata.lastOperationEnum != op) {
      return null;
    }
    return _metadataOperationResult(op);
  }

  ClashSyncApplyResult? applyResultForDisplay({required bool restore}) {
    final memory = restore ? lastRestoreResult : lastApplyResult;
    if (memory != null) {
      return memory;
    }
    final expectedOp = restore ? 'restore' : 'apply';
    if (_metadata.lastOperation != expectedOp) {
      return null;
    }
    return _metadataApplyResult();
  }

  Future<void> _run(Future<ClashSyncOperationResult> Function() action) async {
    authRequired = false;
    busy = true;
    notifyListeners();
    try {
      final result = await action();
      await _recordOperationResult(result);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _recordOperationResult(ClashSyncOperationResult result) async {
    lastResult = result;
    switch (result.operation) {
      case ClashSyncOperation.validate:
        lastValidateResult = result;
      case ClashSyncOperation.pull:
        lastPullResult = result;
      case ClashSyncOperation.push:
        lastPushResult = result;
    }
    _rememberRevision(result);
    await _persistOperationResult(result);
  }

  Future<void> _persistOperationResult(ClashSyncOperationResult result) async {
    final storage = metadataStorage;
    if (storage == null) {
      return;
    }
    _metadata = await storage.updateAfterOperation(
      result,
      hasPendingRemoteSnapshot: hasInMemoryPendingRemoteSnapshot,
      hasLocalBackup: backupStore?.read() != null,
    );
  }

  Future<void> _persistApplyResult(
    ClashSyncApplyResult result, {
    required bool isRestore,
  }) async {
    final storage = metadataStorage;
    if (storage == null) {
      return;
    }
    if (isRestore) {
      lastRestoreResult = result;
    } else {
      lastApplyResult = result;
    }
    _metadata = await storage.updateAfterApply(
      result,
      isRestore: isRestore,
      hasPendingRemoteSnapshot: hasInMemoryPendingRemoteSnapshot,
      hasLocalBackup: backupStore?.read() != null,
    );
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

  ClashSyncOperationResult _metadataOperationResult(ClashSyncOperation op) {
    final status = _metadata.lastStatusEnum ?? ClashSyncStatus.unavailable;
    return ClashSyncOperationResult(
      operation: op,
      status: status,
      serverRevision: status == ClashSyncStatus.conflict
          ? _metadata.lastConflictServerRevision
          : _metadata.knownServerRevision,
      conflict:
          status == ClashSyncStatus.conflict &&
              _metadata.lastConflictServerRevision != null
          ? ClashSyncConflict(
              expectedRevision: null,
              actualRevision: _metadata.lastConflictServerRevision!,
            )
          : null,
      message: _metadata.lastMessage,
      errorCode: _metadata.lastErrorCode,
      completedAt: _operationTimestamp(op),
    );
  }

  DateTime? _operationTimestamp(ClashSyncOperation op) {
    return switch (op) {
      ClashSyncOperation.validate => null,
      ClashSyncOperation.pull => _metadata.lastPullAt,
      ClashSyncOperation.push => _metadata.lastPushAt,
    };
  }

  ClashSyncApplyResult? _metadataApplyResult() {
    final statusName = _metadata.lastStatus;
    if (statusName == null) {
      return null;
    }
    final status = switch (statusName) {
      'success' => ClashSyncApplyStatus.success,
      'validationFailed' => ClashSyncApplyStatus.validationFailed,
      _ => ClashSyncApplyStatus.applyFailed,
    };
    return ClashSyncApplyResult(
      status: status,
      appliedAt: _metadata.lastOperation == 'restore'
          ? _metadata.lastRestoreAt
          : _metadata.lastApplyAt,
      message: _metadata.lastMessage,
      errorCode: _metadata.lastErrorCode,
    );
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
