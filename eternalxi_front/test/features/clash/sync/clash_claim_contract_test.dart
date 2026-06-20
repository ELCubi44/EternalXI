import 'dart:io';

import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClashClaimContract Fase 82', () {
    test('ClashClaimRequest serializa sin userId', () {
      const request = ClashClaimRequest(
        claimId: 'gift:gift-welcome',
        claimType: 'gift',
        sourceId: 'gift-welcome',
        expectedServerRevision: 3,
        payload: {'note': 'optional'},
      );

      final json = request.toJson();

      expect(json['claimId'], 'gift:gift-welcome');
      expect(json['claimType'], 'gift');
      expect(json['sourceId'], 'gift-welcome');
      expect(json['expectedServerRevision'], 3);
      expect(json['payload'], {'note': 'optional'});
      expect(json.containsKey('userId'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json.containsKey('idUsuario'), isFalse);
    });

    test('ClashClaimRequest omite stageId y revision opcionales', () {
      const request = ClashClaimRequest(
        claimId: 'mission:daily-1',
        claimType: 'mission',
        sourceId: 'daily-1',
      );

      final json = request.toJson();

      expect(json.containsKey('stageId'), isFalse);
      expect(json.containsKey('expectedServerRevision'), isFalse);
      expect(json.containsKey('payload'), isFalse);
    });

    test('ClashClaimRequest round-trip mantiene campos', () {
      const original = ClashClaimRequest(
        claimId: 'event:mika:stage-1',
        claimType: 'event',
        sourceId: 'mika',
        stageId: 'stage-1',
        expectedServerRevision: 2,
        payload: {'attempt': 1},
      );

      final decoded = ClashClaimRequest.fromJson(original.toJson());

      expect(decoded, original);
    });

    test('ClashClaimResponse 201 accepted parsea', () {
      final response = ClashClaimResponse.fromJson({
        'claimId': 'gift:gift-welcome',
        'status': 'ACCEPTED',
        'alreadyProcessed': false,
        'serverRevision': 3,
        'rewards': null,
        'message': 'Claim registrado.',
      });

      expect(response.claimId, 'gift:gift-welcome');
      expect(response.status, 'ACCEPTED');
      expect(response.alreadyProcessed, isFalse);
      expect(response.serverRevision, 3);
      expect(response.rawRewards, isNull);
      expect(response.message, 'Claim registrado.');
    });

    test('ClashClaimResponse 200 alreadyProcessed parsea', () {
      final response = ClashClaimResponse.fromJson({
        'claimId': 'gift:gift-welcome',
        'status': 'ACCEPTED',
        'alreadyProcessed': true,
        'serverRevision': 3,
        'message': 'Claim registrado.',
      });

      expect(response.alreadyProcessed, isTrue);
    });

    test('ClashClaimResponse round-trip mantiene campos', () {
      const original = ClashClaimResponse(
        claimId: 'gift:gift-welcome',
        status: 'ACCEPTED',
        alreadyProcessed: false,
        serverRevision: 1,
        rawRewards: null,
        message: 'ok',
      );

      final decoded = ClashClaimResponse.fromJson(original.toJson());

      expect(decoded, original);
    });

    test('módulo claim contract no importa HTTP/API', () {
      final file = File(
        'lib/features/clash/sync/domain/clash_claim_contract.dart',
      );
      final content = file.readAsStringSync();

      expect(content.contains("import 'package:http/"), isFalse);
      expect(content.contains('package:dio/'), isFalse);
      expect(content.contains('ClashApiClient'), isFalse);
    });
  });
}
