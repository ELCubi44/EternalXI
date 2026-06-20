import 'package:eternal_xi/features/clash/sync/data/clash_claim_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_claim_api_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_online_claim_registration_result.dart';

/// Registra claims online de forma opcional y tolerante (Fase 83).
///
/// No concede recompensas locales; no modifica `clash_save`.
class ClashOnlineClaimRegistrar {
  const ClashOnlineClaimRegistrar({
    required this.settingsStorage,
    required this.claimApiClient,
  });

  final ClashSyncSettingsStorage settingsStorage;
  final ClashClaimApiPort claimApiClient;

  Future<ClashOnlineClaimRegistrationResult> registerClaim({
    required ClashClaimRequest request,
  }) async {
    if (!settingsStorage.loadOnlineClaimsEnabled()) {
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.skippedDisabled,
        claimId: request.claimId,
      );
    }

    try {
      final response = await claimApiClient.submitClaim(request);
      if (response.alreadyProcessed) {
        return ClashOnlineClaimRegistrationResult(
          status: ClashOnlineClaimRegistrationStatus.alreadyProcessed,
          claimId: response.claimId,
          response: response,
        );
      }
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.accepted,
        claimId: response.claimId,
        response: response,
      );
    } on ClashClaimValidationException catch (error) {
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.validationFailed,
        claimId: request.claimId,
        errorMessage: error.message,
        errorCode: error.errorCode,
      );
    } on ClashClaimUnauthorizedException catch (error) {
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.unauthorized,
        claimId: request.claimId,
        errorMessage: error.message,
        errorCode: error.errorCode,
      );
    } on ClashClaimConflictException catch (error) {
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.conflict,
        claimId: request.claimId,
        errorMessage: error.message,
        errorCode: error.errorCode,
      );
    } on ClashClaimApiException catch (error) {
      return ClashOnlineClaimRegistrationResult(
        status: ClashOnlineClaimRegistrationStatus.failed,
        claimId: request.claimId,
        errorMessage: error.message,
        errorCode: error.errorCode,
      );
    }
  }
}
