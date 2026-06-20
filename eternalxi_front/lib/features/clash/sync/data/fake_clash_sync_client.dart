import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';

/// Cliente fake de sync Clash en memoria (Fase 67).
///
/// Simula push/pull, `serverRevision` y conflictos sin red ni persistencia real.
class FakeClashSyncClient extends ClashSyncClient {
  FakeClashSyncClient({
    ClashSyncSnapshotValidator? validator,
    Set<int>? supportedContractVersions,
    this.available = true,
  }) : _validator = validator ?? const ClashSyncSnapshotValidator(),
       _supportedContractVersions =
           supportedContractVersions ?? {ClashSyncContractVersion.current};

  final ClashSyncSnapshotValidator _validator;
  final Set<int> _supportedContractVersions;

  /// Si es `false`, push/pull devuelven [ClashSyncStatus.unavailable].
  bool available;

  ClashSyncSnapshot? _remoteSnapshot;
  int _serverRevision = 0;

  int get serverRevision => _serverRevision;

  ClashSyncSnapshot? get remoteSnapshot => _remoteSnapshot;

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    if (!available) {
      return ClashSyncPushResult.unavailable();
    }

    if (!_supportedContractVersions.contains(snapshot.contractVersion)) {
      return ClashSyncPushResult.rejected(
        errorCode: 'unsupported_contract_version',
        message: 'contractVersion ${snapshot.contractVersion} is not supported',
      );
    }

    final validation = _validator.validate(snapshot);
    if (!validation.isValid) {
      return ClashSyncPushResult.validationFailed(validationResult: validation);
    }

    if (expectedServerRevision != null &&
        expectedServerRevision != _serverRevision) {
      return ClashSyncPushResult.conflict(
        conflict: ClashSyncConflict(
          expectedRevision: expectedServerRevision,
          actualRevision: _serverRevision,
          remoteSnapshot: _remoteSnapshot,
        ),
      );
    }

    _serverRevision += 1;
    _remoteSnapshot = snapshot;

    return ClashSyncPushResult.success(
      serverRevision: _serverRevision,
      snapshot: snapshot,
    );
  }

  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    if (!available) {
      return ClashSyncPullResult.unavailable();
    }

    final snapshot = _remoteSnapshot;
    if (snapshot == null) {
      return ClashSyncPullResult.notFound();
    }

    return ClashSyncPullResult.success(
      serverRevision: _serverRevision,
      snapshot: snapshot,
    );
  }

  /// Reinicia el estado remoto simulado (solo tests).
  void reset() {
    _remoteSnapshot = null;
    _serverRevision = 0;
  }
}
