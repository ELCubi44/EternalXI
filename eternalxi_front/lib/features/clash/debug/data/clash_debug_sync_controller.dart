import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:flutter/foundation.dart';

/// Estado en memoria del panel manual de sync online en diagnóstico (Fase 72).
class ClashDebugSyncController extends ChangeNotifier {
  ClashDebugSyncController({required this.coordinator, this.isAuthenticated});

  final ClashSyncCoordinator coordinator;
  final Future<bool> Function()? isAuthenticated;

  ClashSyncOperationResult? lastResult;
  int? knownServerRevision;
  bool busy = false;
  bool authRequired = false;

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
      return result;
    });
  }

  Future<void> pushLocal() async {
    if (!await _ensureAuthenticated()) {
      return;
    }
    await _run(() async {
      if (knownServerRevision != null) {
        final result = await coordinator.pushLocalSnapshot(
          expectedServerRevision: knownServerRevision,
        );
        _rememberRevision(result);
        return result;
      }

      final probe = await coordinator.pullRemoteSnapshot();
      if (probe.isNotFound) {
        final created = await coordinator.pushLocalSnapshot();
        _rememberRevision(created);
        return created;
      }
      if (!probe.isSuccess) {
        return _asPushResult(probe);
      }

      knownServerRevision = probe.serverRevision;
      final updated = await coordinator.pushLocalSnapshot(
        expectedServerRevision: knownServerRevision,
      );
      _rememberRevision(updated);
      return updated;
    });
  }

  Future<void> _run(Future<ClashSyncOperationResult> Function() action) async {
    authRequired = false;
    busy = true;
    notifyListeners();
    try {
      lastResult = await action();
    } finally {
      busy = false;
      notifyListeners();
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
