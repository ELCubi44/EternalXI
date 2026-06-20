/// Lógica de visibilidad del aviso de partida online pendiente (Fase 80).
class ClashPendingSyncNoticePresentation {
  const ClashPendingSyncNoticePresentation._();

  static bool shouldShow({
    required bool hasPendingRemoteSnapshot,
    required int? knownServerRevision,
    required int? dismissedRevision,
  }) {
    if (!hasPendingRemoteSnapshot) {
      return false;
    }
    if (knownServerRevision == null || knownServerRevision <= 0) {
      return false;
    }
    return dismissedRevision != knownServerRevision;
  }
}
