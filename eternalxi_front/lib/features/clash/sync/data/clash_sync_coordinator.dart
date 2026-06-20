import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_operation_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';

/// Orquestador local del flujo de sync Clash (Fase 68).
///
/// Coordina build → validate → push/pull sin red ni aplicación de datos remotos
/// sobre persistencia local.
class ClashSyncCoordinator {
  const ClashSyncCoordinator({
    required this.builder,
    required this.validator,
    required this.client,
    this.now,
  });

  final ClashSyncSnapshotBuilder builder;
  final ClashSyncSnapshotValidator validator;
  final ClashSyncClient client;
  final DateTime Function()? now;

  /// Construye y valida el snapshot local sin contactar al cliente sync.
  Future<ClashSyncOperationResult> validateLocalSnapshotOnly() async {
    final startedAt = _now();
    final snapshot = await builder.build();
    final validation = validator.validate(snapshot);
    return ClashSyncOperationResult.fromValidation(
      validationResult: validation,
      snapshot: snapshot,
      startedAt: startedAt,
      completedAt: _now(),
    );
  }

  /// Construye, valida y sube el snapshot local si es válido.
  ///
  /// Si la validación local falla, **no** llama a [ClashSyncClient.pushSnapshot].
  Future<ClashSyncOperationResult> pushLocalSnapshot({
    int? expectedServerRevision,
  }) async {
    final startedAt = _now();
    final snapshot = await builder.build();
    final validation = validator.validate(snapshot);

    if (!validation.isValid) {
      return ClashSyncOperationResult.fromPush(
        pushResult: ClashSyncPushResult.validationFailed(
          validationResult: validation,
        ),
        localSnapshot: snapshot,
        localValidation: validation,
        startedAt: startedAt,
        completedAt: _now(),
      );
    }

    final pushResult = await client.pushSnapshot(
      snapshot,
      expectedServerRevision: expectedServerRevision,
    );

    return ClashSyncOperationResult.fromPush(
      pushResult: pushResult,
      localSnapshot: snapshot,
      localValidation: validation,
      startedAt: startedAt,
      completedAt: _now(),
    );
  }

  /// Descarga el snapshot remoto, lo valida y lo devuelve sin aplicarlo localmente.
  Future<ClashSyncOperationResult> pullRemoteSnapshot() async {
    final startedAt = _now();
    final pullResult = await client.pullSnapshot();

    if (pullResult.status != ClashSyncStatus.success ||
        pullResult.snapshot == null) {
      return ClashSyncOperationResult.fromPull(
        pullResult: pullResult,
        startedAt: startedAt,
        completedAt: _now(),
      );
    }

    final remoteValidation = validator.validate(pullResult.snapshot!);
    return ClashSyncOperationResult.fromPull(
      pullResult: pullResult,
      remoteValidation: remoteValidation,
      startedAt: startedAt,
      completedAt: _now(),
    );
  }

  DateTime _now() => now?.call() ?? DateTime.now().toUtc();
}
