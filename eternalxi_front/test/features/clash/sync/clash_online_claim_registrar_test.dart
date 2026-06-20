import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_online_claim_registrar.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_claim_api_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_online_claim_registration_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ClashOnlineClaimRegistrar Fase 83', () {
    late SharedPreferences prefs;
    late ClashSyncSettingsStorage settingsStorage;
    late FakeClashClaimApiClient apiClient;
    late ClashOnlineClaimRegistrar registrar;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      settingsStorage = ClashSyncSettingsStorage(sharedPreferences: prefs);
      apiClient = FakeClashClaimApiClient();
      registrar = ClashOnlineClaimRegistrar(
        settingsStorage: settingsStorage,
        claimApiClient: apiClient,
      );
    });

    test('flag false no llama API', () async {
      final result = await registrar.registerClaim(request: _request());

      expect(result.status, ClashOnlineClaimRegistrationStatus.skippedDisabled);
      expect(result.shouldContinueLocalGrant, isTrue);
      expect(apiClient.submitCalls, 0);
    });

    test('flag true llama API y accepted', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);

      final result = await registrar.registerClaim(request: _request());

      expect(result.status, ClashOnlineClaimRegistrationStatus.accepted);
      expect(result.shouldContinueLocalGrant, isTrue);
      expect(apiClient.submitCalls, 1);
      expect(apiClient.lastRequestJson?.containsKey('userId'), isFalse);
    });

    test('alreadyProcessed no debe repetir grant local', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);
      apiClient.nextResponse = _response(alreadyProcessed: false);
      await registrar.registerClaim(request: _request());
      apiClient.nextResponse = _response(alreadyProcessed: true);

      final result = await registrar.registerClaim(request: _request());

      expect(
        result.status,
        ClashOnlineClaimRegistrationStatus.alreadyProcessed,
      );
      expect(result.shouldContinueLocalGrant, isFalse);
    });

    test('400 validationFailed tolerante', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);
      apiClient.nextError = const ClashClaimValidationException(
        message: 'claimId es obligatorio',
      );

      final result = await registrar.registerClaim(request: _request());

      expect(
        result.status,
        ClashOnlineClaimRegistrationStatus.validationFailed,
      );
      expect(result.shouldContinueLocalGrant, isTrue);
    });

    test('401 unauthorized tolerante', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);
      apiClient.nextError = const ClashClaimUnauthorizedException();

      final result = await registrar.registerClaim(request: _request());

      expect(result.status, ClashOnlineClaimRegistrationStatus.unauthorized);
      expect(result.shouldContinueLocalGrant, isTrue);
    });

    test('409 conflict tolerante', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);
      apiClient.nextError = const ClashClaimConflictException();

      final result = await registrar.registerClaim(request: _request());

      expect(result.status, ClashOnlineClaimRegistrationStatus.conflict);
      expect(result.shouldContinueLocalGrant, isTrue);
    });

    test('error genérico failed tolerante', () async {
      await settingsStorage.setOnlineClaimsEnabled(true);
      apiClient.nextError = const ClashClaimApiException(
        statusCode: 500,
        message: 'server error',
      );

      final result = await registrar.registerClaim(request: _request());

      expect(result.status, ClashOnlineClaimRegistrationStatus.failed);
      expect(result.shouldContinueLocalGrant, isTrue);
    });
  });
}

ClashClaimRequest _request() {
  return const ClashClaimRequest(
    claimId: 'gift:gift-welcome',
    claimType: 'gift',
    sourceId: 'gift-welcome',
  );
}

ClashClaimResponse _response({required bool alreadyProcessed}) {
  return ClashClaimResponse(
    claimId: 'gift:gift-welcome',
    status: 'ACCEPTED',
    alreadyProcessed: alreadyProcessed,
    message: 'ok',
  );
}
