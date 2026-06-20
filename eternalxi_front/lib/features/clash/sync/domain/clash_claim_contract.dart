/// DTOs de contrato para `POST /api/v1/clash/claims` (Fase 82).
class ClashClaimRequest {
  const ClashClaimRequest({
    required this.claimId,
    required this.claimType,
    required this.sourceId,
    this.stageId,
    this.expectedServerRevision,
    this.payload,
  });

  final String claimId;
  final String claimType;
  final String sourceId;
  final String? stageId;
  final int? expectedServerRevision;
  final Map<String, dynamic>? payload;

  Map<String, dynamic> toJson() => {
    'claimId': claimId,
    'claimType': claimType,
    'sourceId': sourceId,
    if (stageId != null) 'stageId': stageId,
    if (expectedServerRevision != null)
      'expectedServerRevision': expectedServerRevision,
    if (payload != null) 'payload': payload,
  };

  factory ClashClaimRequest.fromJson(Map<String, dynamic> json) {
    final revisionRaw = json['expectedServerRevision'];
    final payloadRaw = json['payload'];
    return ClashClaimRequest(
      claimId: json['claimId']?.toString() ?? '',
      claimType: json['claimType']?.toString() ?? '',
      sourceId: json['sourceId']?.toString() ?? '',
      stageId: json['stageId']?.toString(),
      expectedServerRevision: revisionRaw == null
          ? null
          : _readInt(revisionRaw),
      payload: payloadRaw == null
          ? null
          : Map<String, dynamic>.from(payloadRaw as Map),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashClaimRequest &&
        other.claimId == claimId &&
        other.claimType == claimType &&
        other.sourceId == sourceId &&
        other.stageId == stageId &&
        other.expectedServerRevision == expectedServerRevision &&
        _mapEquals(other.payload, payload);
  }

  @override
  int get hashCode => Object.hash(
    claimId,
    claimType,
    sourceId,
    stageId,
    expectedServerRevision,
    payload == null ? null : Object.hashAll(payload!.entries),
  );
}

/// Respuesta idempotente de claim server-side.
class ClashClaimResponse {
  const ClashClaimResponse({
    required this.claimId,
    required this.status,
    required this.alreadyProcessed,
    this.serverRevision,
    this.rawRewards,
    this.message,
  });

  final String claimId;
  final String status;
  final bool alreadyProcessed;
  final int? serverRevision;
  final Object? rawRewards;
  final String? message;

  Map<String, dynamic> toJson() => {
    'claimId': claimId,
    'status': status,
    'alreadyProcessed': alreadyProcessed,
    if (serverRevision != null) 'serverRevision': serverRevision,
    if (rawRewards != null) 'rewards': rawRewards,
    if (message != null) 'message': message,
  };

  factory ClashClaimResponse.fromJson(Map<String, dynamic> json) {
    final revisionRaw = json['serverRevision'];
    return ClashClaimResponse(
      claimId: json['claimId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      alreadyProcessed: json['alreadyProcessed'] == true,
      serverRevision: revisionRaw == null ? null : _readInt(revisionRaw),
      rawRewards: json['rewards'],
      message: json['message']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ClashClaimResponse &&
        other.claimId == claimId &&
        other.status == status &&
        other.alreadyProcessed == alreadyProcessed &&
        other.serverRevision == serverRevision &&
        other.rawRewards == rawRewards &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
    claimId,
    status,
    alreadyProcessed,
    serverRevision,
    rawRewards,
    message,
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

bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
  if (identical(a, b)) {
    return true;
  }
  if (a == null || b == null || a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}
