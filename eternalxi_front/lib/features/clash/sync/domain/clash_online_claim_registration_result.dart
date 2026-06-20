import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';

enum ClashOnlineClaimRegistrationStatus {
  skippedDisabled,
  accepted,
  alreadyProcessed,
  failed,
  unauthorized,
  validationFailed,
  conflict,
}

/// Resultado del registro opcional de un claim online (Fase 83).
class ClashOnlineClaimRegistrationResult {
  const ClashOnlineClaimRegistrationResult({
    required this.status,
    required this.claimId,
    this.response,
    this.errorMessage,
    this.errorCode,
  });

  final ClashOnlineClaimRegistrationStatus status;
  final String claimId;
  final ClashClaimResponse? response;
  final String? errorMessage;
  final String? errorCode;

  bool get alreadyProcessed =>
      status == ClashOnlineClaimRegistrationStatus.alreadyProcessed;

  bool get shouldContinueLocalGrant => switch (status) {
    ClashOnlineClaimRegistrationStatus.skippedDisabled => true,
    ClashOnlineClaimRegistrationStatus.accepted => true,
    ClashOnlineClaimRegistrationStatus.alreadyProcessed => false,
    ClashOnlineClaimRegistrationStatus.failed => true,
    ClashOnlineClaimRegistrationStatus.unauthorized => true,
    ClashOnlineClaimRegistrationStatus.validationFailed => true,
    ClashOnlineClaimRegistrationStatus.conflict => true,
  };
}
