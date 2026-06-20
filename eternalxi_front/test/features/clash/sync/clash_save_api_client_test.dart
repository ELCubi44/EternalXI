import 'package:dio/dio.dart';
import 'package:eternal_xi/core/constants/api_constants.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_save_api_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_api_exception.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_save_contract.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_contract_version.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClashSaveApiClient Fase 71', () {
    test('GET 200 parsea save', () async {
      final client = _clientWithHandler((options) {
        expect(options.path, ApiConstants.clashSave);
        expect(options.method, 'GET');
        return _jsonResponse(options, 200, _saveJson(revision: 2));
      });

      final save = await client.getSave();

      expect(save, isNotNull);
      expect(save!.serverRevision, 2);
      expect(save.saveData.wallet.coins, 1500);
    });

    test('GET 404 devuelve null', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 404, {'error': 'CLASH_SAVE_NOT_FOUND'});
      });

      expect(await client.getSave(), isNull);
    });

    test('POST 201 crea save', () async {
      final client = _clientWithHandler((options) {
        expect(options.method, 'POST');
        expect(options.path, ApiConstants.clashSave);
        final body = options.data as Map<String, dynamic>;
        expect(body.containsKey('userId'), isFalse);
        expect(body.containsKey('idUsuario'), isFalse);
        return _jsonResponse(options, 201, _saveJson(revision: 1));
      });

      final created = await client.createSave(_request());

      expect(created.serverRevision, 1);
    });

    test('POST 409 produce conflicto tipado', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 409, {
          'error': 'CLASH_SAVE_ALREADY_EXISTS',
          'message': 'Ya existe una partida Clash para este usuario',
        });
      });

      expect(
        () => client.createSave(_request()),
        throwsA(
          isA<ClashSaveApiException>().having(
            (error) => error.statusCode,
            'statusCode',
            409,
          ),
        ),
      );
    });

    test('PUT 200 actualiza save', () async {
      final client = _clientWithHandler((options) {
        expect(options.method, 'PUT');
        final body = options.data as Map<String, dynamic>;
        expect(body['expectedServerRevision'], 1);
        return _jsonResponse(options, 200, _saveJson(revision: 2));
      });

      final updated = await client.updateSave(_request(expectedRevision: 1));

      expect(updated.serverRevision, 2);
    });

    test('PUT 409 parsea ClashSaveConflictResponse', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 409, {
          'serverRevision': 3,
          'serverSaveData': _sampleSnapshot().toJson(),
          'clientRejectedReason': 'expectedServerRevision 2 != current 3',
        });
      });

      expect(
        () => client.updateSave(_request(expectedRevision: 2)),
        throwsA(
          isA<ClashSaveConflictException>()
              .having((e) => e.conflictResponse.serverRevision, 'revision', 3)
              .having(
                (e) => e.conflictResponse.serverSaveData.wallet.coins,
                'coins',
                1500,
              ),
        ),
      );
    });

    test('PUT 404 produce notFound', () async {
      final client = _clientWithHandler((options) {
        return _jsonResponse(options, 404, {
          'error': 'CLASH_SAVE_NOT_FOUND',
          'message': 'No existe partida Clash para este usuario',
        });
      });

      expect(
        () => client.updateSave(_request(expectedRevision: 1)),
        throwsA(isA<ClashSaveNotFoundException>()),
      );
    });

    test('request no contiene userId', () async {
      final client = _clientWithHandler((options) {
        final body = options.data as Map<String, dynamic>;
        expect(body.keys, isNot(contains('userId')));
        expect(body.keys, isNot(contains('user_id')));
        expect(body.keys, isNot(contains('idUsuario')));
        return _jsonResponse(options, 201, _saveJson(revision: 1));
      });

      await client.createSave(_request());
    });

    test('usa ruta /clash/save correctamente', () async {
      final client = _clientWithHandler((options) {
        expect(options.uri.path, endsWith('/api/v1/clash/save'));
        return _jsonResponse(options, 200, _saveJson(revision: 1));
      });

      await client.getSave();
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashSaveApiClient _clientWithHandler(
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
  return ClashSaveApiClient(dio);
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

Map<String, dynamic> _saveJson({required int revision}) {
  return {
    'serverRevision': revision,
    'contractVersion': ClashSyncContractVersion.current,
    'schemaVersion': ClashStorageSchema.currentVersion,
    'updatedAt': '2026-06-20T14:30:00.000Z',
    'saveData': _sampleSnapshot().toJson(),
  };
}

ClashSaveUpdateRequest _request({int? expectedRevision}) {
  return ClashSaveUpdateRequest(
    expectedServerRevision: expectedRevision,
    contractVersion: ClashSyncContractVersion.current,
    schemaVersion: ClashStorageSchema.currentVersion,
    saveData: _sampleSnapshot(),
    clientGeneratedAt: _epoch,
  );
}

ClashSyncSnapshot _sampleSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: ClashStorageSchema.currentVersion,
    wallet: const ClashSyncWallet(coins: 1500, gems: 12),
    collection: const ClashSyncCollection(
      ownedCardIds: ['card-a'],
      uniqueCount: 1,
      totalCopies: 1,
    ),
  );
}
