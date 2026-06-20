import 'package:eternal_xi/features/clash/sync/data/clash_save_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';

/// [ClashSyncClient] backed by HTTP `/api/v1/clash/save` (Fase 71).
///
/// No valida snapshot ni aplica datos locales; pensado para usar con
/// [ClashSyncCoordinator]. No activa sync automática.
class HttpClashSyncClient extends ClashSyncClient {
  const HttpClashSyncClient(this._saveApiClient);

  final ClashSaveApiPort _saveApiClient;

  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    try {
      final save = await _saveApiClient.getSave();
      if (save == null) {
        return ClashSyncPullResult.notFound();
      }
      return ClashSyncPullResult.success(
        serverRevision: save.serverRevision,
        snapshot: save.saveData,
      );
    } on ClashSaveApiException catch (error) {
      if (error.statusCode == 404) {
        return ClashSyncPullResult.notFound(message: error.message);
      }
      return ClashSyncPullResult.unavailable(message: error.message);
    }
  }

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    final request = ClashSaveUpdateRequest(
      expectedServerRevision: expectedServerRevision,
      contractVersion: snapshot.contractVersion,
      schemaVersion: snapshot.schemaVersion,
      saveData: snapshot,
      clientGeneratedAt: snapshot.generatedAt,
    );

    try {
      final ClashSaveResponse response;
      if (expectedServerRevision != null) {
        response = await _saveApiClient.updateSave(request);
      } else {
        response = await _saveApiClient.createSave(request);
      }
      return ClashSyncPushResult.success(
        serverRevision: response.serverRevision,
        snapshot: response.saveData,
      );
    } on ClashSaveConflictException catch (error) {
      final conflict = error.conflictResponse;
      return ClashSyncPushResult.conflict(
        conflict: ClashSyncConflict(
          expectedRevision: expectedServerRevision,
          actualRevision: conflict.serverRevision,
          remoteSnapshot: conflict.serverSaveData,
        ),
        message: error.message,
      );
    } on ClashSaveNotFoundException catch (error) {
      return ClashSyncPushResult.rejected(
        errorCode: error.errorCode ?? 'CLASH_SAVE_NOT_FOUND',
        message: error.message,
      );
    } on ClashSaveApiException catch (error) {
      if (error.statusCode == 409) {
        return ClashSyncPushResult.rejected(
          errorCode: error.errorCode ?? 'conflict',
          message: error.message,
        );
      }
      return ClashSyncPushResult.unavailable(message: error.message);
    }
  }
}
