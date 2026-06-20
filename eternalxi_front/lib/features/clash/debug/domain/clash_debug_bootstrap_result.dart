/// Resultado del bootstrap manual de partida online (Fase 77).
enum ClashDebugBootstrapStatus {
  remoteFound,
  remoteCreated,
  validationFailed,
  unauthorized,
  unavailable,
  error,
}

class ClashDebugBootstrapResult {
  const ClashDebugBootstrapResult({
    required this.status,
    this.serverRevision,
    this.message,
    this.errorCode,
  });

  final ClashDebugBootstrapStatus status;
  final int? serverRevision;
  final String? message;
  final String? errorCode;

  bool get isRemoteFound => status == ClashDebugBootstrapStatus.remoteFound;

  bool get isRemoteCreated => status == ClashDebugBootstrapStatus.remoteCreated;
}
