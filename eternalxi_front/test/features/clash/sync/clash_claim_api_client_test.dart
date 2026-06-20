import 'dart:io';

import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_claim_api_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_claim_contract.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sync_layer_http_guard.dart';

void main() {
  group('ClashClaimApiClient Fase 82', () {
    test('POST 201 accepted parsea respuesta', () async {
      final client = _clientWithHandler((options) {
        expect(options.method, 'POST');
        expect(options.path, ApiConstants.clashClaims);
        final body = options.data as Map<String, dynamic>;
        expect(body.containsKey('userId'), isFalse);
        expect(body.containsKey('idUsuario'), isFalse);
        return _jsonResponse(options, 201, _claimJson(alreadyProcessed: false));
      });

      final response = await client.submitClaim(_request());

      expect(response.status, 'ACCEPTED');
      expect(response.alreadyProcessed, isFalse);
      expect(response.claimId, 'gift:gift-welcome');
    });

    test('POST 200 alreadyProcessed parsea respuesta', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 200, _claimJson(alreadyProcessed: true));
      });

      final response = await client.submitClaim(_request());

      expect(response.alreadyProcessed, isTrue);
    });

    test('400 lanza ClashClaimValidationException', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 400, {
          'error': 'VALIDATION_ERROR',
          'message': 'claimId es obligatorio',
        });
      });

      expect(
        () => client.submitClaim(_request()),
        throwsA(
          isA<ClashClaimValidationException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errorCode, 'errorCode', 'VALIDATION_ERROR'),
        ),
      );
    });

    test('401 lanza ClashClaimUnauthorizedException', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 401, {
          'error': 'UNAUTHORIZED',
          'message': 'Debes iniciar sesión para continuar.',
        });
      });

      expect(
        () => client.submitClaim(_request()),
        throwsA(isA<ClashClaimUnauthorizedException>()),
      );
    });

    test('409 lanza ClashClaimConflictException', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 409, {
          'error': 'CLASH_CLAIM_CONFLICT',
          'message': 'Conflicto de revisión',
        });
      });

      expect(
        () => client.submitClaim(_request()),
        throwsA(isA<ClashClaimConflictException>()),
      );
    });

    test('payload opcional se serializa', () async {
      final client = _clientWithHandler((options) {
        final body = options.data as Map<String, dynamic>;
        expect(body['payload'], {'note': 'optional'});
        return _jsonResponse(options, 201, _claimJson(alreadyProcessed: false));
      });

      await client.submitClaim(_request(payload: const {'note': 'optional'}));
    });

    test('stageId y expectedServerRevision opcionales se serializan', () async {
      final client = _clientWithHandler((options) {
        final body = options.data as Map<String, dynamic>;
        expect(body['stageId'], 'stage-1');
        expect(body['expectedServerRevision'], 5);
        return _jsonResponse(options, 201, _claimJson(alreadyProcessed: false));
      });

      await client.submitClaim(
        const ClashClaimRequest(
          claimId: 'event:mika:stage-1',
          claimType: 'event',
          sourceId: 'mika',
          stageId: 'stage-1',
          expectedServerRevision: 5,
        ),
      );
    });

    test('usa ruta /api/v1/clash/claims', () async {
      final client = _clientWithHandler((options) {
        expect(options.uri.path, endsWith('/api/v1/clash/claims'));
        return _jsonResponse(options, 201, _claimJson(alreadyProcessed: false));
      });

      await client.submitClaim(_request());
    });

    test('no está registrado en clash_providers', () {
      final providersFile = File(
        'lib/features/clash/shared/di/clash_providers.dart',
      );
      final content = providersFile.readAsStringSync();

      expect(content.contains('ClashClaimApiClient'), isFalse);
      expect(content.contains('clash_claim_api_client'), isFalse);
    });

    test('sync layer guard permite solo clientes HTTP declarados', () {
      expect(findForbiddenHttpImportsInSyncLayer(), isEmpty);
    });
  });
}

ClashClaimApiClient _clientWithHandler(
  Response<dynamic> Function(RequestOptions options) handler,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.eternalxi.com/api/v1'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handlerInterceptor) {
        handlerInterceptor.resolve(handler(options));
      },
    ),
  );
  return ClashClaimApiClient(dio);
}

Response<dynamic> _jsonResponse(
  RequestOptions options,
  int statusCode,
  Map<String, dynamic> data,
) {
  return Response<dynamic>(
    requestOptions: options,
    statusCode: statusCode,
    data: data,
  );
}

Map<String, dynamic> _claimJson({required bool alreadyProcessed}) {
  return {
    'claimId': 'gift:gift-welcome',
    'status': 'ACCEPTED',
    'alreadyProcessed': alreadyProcessed,
    'serverRevision': 3,
    'rewards': null,
    'message': 'Claim registrado.',
  };
}

ClashClaimRequest _request({Map<String, dynamic>? payload}) {
  return ClashClaimRequest(
    claimId: 'gift:gift-welcome',
    claimType: 'gift',
    sourceId: 'gift-welcome',
    payload: payload,
  );
}
