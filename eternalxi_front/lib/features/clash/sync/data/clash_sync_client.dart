import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';

/// Contrato del cliente de sync Clash (Fase 67).
///
/// Implementaciones futuras usarán HTTP; esta fase solo define la interfaz
/// y un cliente fake en memoria para pruebas.
abstract class ClashSyncClient {
  const ClashSyncClient();

  /// Sube un snapshot local al servidor remoto.
  ///
  /// [expectedServerRevision] simula optimistic concurrency: si no coincide
  /// con la revisión remota actual, la operación devuelve [ClashSyncStatus.conflict].
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  });

  /// Descarga el snapshot remoto autoritativo, si existe.
  Future<ClashSyncPullResult> pullSnapshot();
}
