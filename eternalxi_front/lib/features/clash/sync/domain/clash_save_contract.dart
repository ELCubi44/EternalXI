import 'clash_sync_contract_version.dart';
import 'clash_sync_snapshot.dart';

/// Respuesta del backend al cargar/actualizar partida Clash (Fase 69).
class ClashSaveResponse {
  const ClashSaveResponse({
    required this.serverRevision,
    required this.contractVersion,
    required this.schemaVersion,
    required this.saveData,
    required this.updatedAt,
  });

  final int serverRevision;
  final int contractVersion;
  final int schemaVersion;
  final ClashSyncSnapshot saveData;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
    'serverRevision': serverRevision,
    'contractVersion': contractVersion,
    'schemaVersion': schemaVersion,
    'saveData': saveData.toJson(),
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };

  factory ClashSaveResponse.fromJson(Map<String, dynamic> json) {
    return ClashSaveResponse(
      serverRevision: _readInt(json['serverRevision']),
      contractVersion: _readInt(
        json['contractVersion'],
        fallback: ClashSyncContractVersion.current,
      ),
      schemaVersion: _readInt(json['schemaVersion']),
      saveData: ClashSyncSnapshot.fromJson(
        Map<String, dynamic>.from(json['saveData'] as Map),
      ),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSaveResponse &&
        other.serverRevision == serverRevision &&
        other.contractVersion == contractVersion &&
        other.schemaVersion == schemaVersion &&
        other.saveData == saveData &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    serverRevision,
    contractVersion,
    schemaVersion,
    saveData,
    updatedAt,
  );
}

/// Petición de actualización/creación de partida Clash online.
class ClashSaveUpdateRequest {
  const ClashSaveUpdateRequest({
    required this.contractVersion,
    required this.schemaVersion,
    required this.saveData,
    required this.clientGeneratedAt,
    this.expectedServerRevision,
  });

  final int? expectedServerRevision;
  final int contractVersion;
  final int schemaVersion;
  final ClashSyncSnapshot saveData;
  final DateTime clientGeneratedAt;

  Map<String, dynamic> toJson() => {
    if (expectedServerRevision != null)
      'expectedServerRevision': expectedServerRevision,
    'contractVersion': contractVersion,
    'schemaVersion': schemaVersion,
    'clientGeneratedAt': clientGeneratedAt.toUtc().toIso8601String(),
    'saveData': saveData.toJson(),
  };

  factory ClashSaveUpdateRequest.fromJson(Map<String, dynamic> json) {
    final revisionRaw = json['expectedServerRevision'];
    return ClashSaveUpdateRequest(
      expectedServerRevision: revisionRaw == null
          ? null
          : _readInt(revisionRaw),
      contractVersion: _readInt(
        json['contractVersion'],
        fallback: ClashSyncContractVersion.current,
      ),
      schemaVersion: _readInt(json['schemaVersion']),
      saveData: ClashSyncSnapshot.fromJson(
        Map<String, dynamic>.from(json['saveData'] as Map),
      ),
      clientGeneratedAt:
          DateTime.tryParse(json['clientGeneratedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSaveUpdateRequest &&
        other.expectedServerRevision == expectedServerRevision &&
        other.contractVersion == contractVersion &&
        other.schemaVersion == schemaVersion &&
        other.saveData == saveData &&
        other.clientGeneratedAt == clientGeneratedAt;
  }

  @override
  int get hashCode => Object.hash(
    expectedServerRevision,
    contractVersion,
    schemaVersion,
    saveData,
    clientGeneratedAt,
  );
}

/// Respuesta HTTP 409 cuando la revisión del cliente no coincide (Fase 69).
class ClashSaveConflictResponse {
  const ClashSaveConflictResponse({
    required this.serverRevision,
    required this.serverSaveData,
    this.clientRejectedReason,
  });

  final int serverRevision;
  final ClashSyncSnapshot serverSaveData;
  final String? clientRejectedReason;

  Map<String, dynamic> toJson() => {
    'serverRevision': serverRevision,
    'serverSaveData': serverSaveData.toJson(),
    if (clientRejectedReason != null)
      'clientRejectedReason': clientRejectedReason,
  };

  factory ClashSaveConflictResponse.fromJson(Map<String, dynamic> json) {
    return ClashSaveConflictResponse(
      serverRevision: _readInt(json['serverRevision']),
      serverSaveData: ClashSyncSnapshot.fromJson(
        Map<String, dynamic>.from(json['serverSaveData'] as Map),
      ),
      clientRejectedReason: json['clientRejectedReason']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSaveConflictResponse &&
        other.serverRevision == serverRevision &&
        other.serverSaveData == serverSaveData &&
        other.clientRejectedReason == clientRejectedReason;
  }

  @override
  int get hashCode =>
      Object.hash(serverRevision, serverSaveData, clientRejectedReason);
}

/// Petición futura de claim server-side idempotente (Fase 69 — documentado).
class ClashSaveClaimRequest {
  const ClashSaveClaimRequest({
    required this.claimId,
    required this.claimType,
    required this.sourceId,
    this.stageId,
    this.expectedServerRevision,
  });

  final String claimId;
  final String claimType;
  final String sourceId;
  final String? stageId;
  final int? expectedServerRevision;

  Map<String, dynamic> toJson() => {
    'claimId': claimId,
    'claimType': claimType,
    'sourceId': sourceId,
    if (stageId != null) 'stageId': stageId,
    if (expectedServerRevision != null)
      'expectedServerRevision': expectedServerRevision,
  };

  factory ClashSaveClaimRequest.fromJson(Map<String, dynamic> json) {
    final revisionRaw = json['expectedServerRevision'];
    return ClashSaveClaimRequest(
      claimId: json['claimId']?.toString() ?? '',
      claimType: json['claimType']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      stageId: json['stageId']?.toString(),
      expectedServerRevision: revisionRaw == null
          ? null
          : _readInt(revisionRaw),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashSaveClaimRequest &&
        other.claimId == claimId &&
        other.claimType == claimType &&
        other.sourceId == sourceId &&
        other.stageId == stageId &&
        other.expectedServerRevision == expectedServerRevision;
  }

  @override
  int get hashCode => Object.hash(
    claimId,
    claimType,
    sourceId,
    stageId,
    expectedServerRevision,
  );
}

int _readInt(Object? value, {int fallback = 0}) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}
