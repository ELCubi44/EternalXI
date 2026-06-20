import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/debug/data/clash_debug_sync_controller.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_applier.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_apply_status.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/clash_providers_test.dart';

Future<SharedPreferences> _mockPrefs() async {
  SharedPreferences.setMockInitialValues({
    ClashSharedPreferencesKeys.schemaVersion: 1,
    ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
  });
  return SharedPreferences.getInstance();
}

Future<void> _pumpUntilDebugLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 120; i++) {
    if (find.text('Sincronización online').evaluate().isNotEmpty ||
        find
            .text('No se pudo cargar el diagnóstico local.')
            .evaluate()
            .isNotEmpty) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('ClashDebugScreen no terminó de cargar');
}

Future<void> _bindTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return Future.value();
}

Future<void> _tapSyncAction(WidgetTester tester, String label) async {
  final finder = find.text(label);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapSyncWidget(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Widget _debugApp({
  required List<SingleChildWidget> providers,
  SharedPreferences? sharedPreferences,
  ClashDebugSyncController? syncController,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ClashDebugScreen(
        key: ValueKey(syncController ?? sharedPreferences),
        sharedPreferences: sharedPreferences,
        syncController: syncController,
      ),
    ),
  );
}

ClashDebugSyncController _syncController(
  ClashSyncClient client, {
  ClashSyncSnapshotApplier? applier,
}) {
  return ClashDebugSyncController(
    coordinator: ClashSyncCoordinator(
      builder: _StubSnapshotBuilder(_validSnapshot()),
      validator: const ClashSyncSnapshotValidator(),
      client: client,
      now: () => _epoch,
    ),
    applier: applier,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      ClashSharedPreferencesKeys.schemaVersion: 1,
      ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
    });
  });

  group('ClashDebugScreen sync Fase 72–77', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
      });
    });

    testWidgets('flujo manual de diagnóstico sync online', (tester) async {
      await _bindTallViewport(tester);
      final prefs = await _mockPrefs();
      final client = FakeClashSyncClient();
      final controller = _syncController(client);
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _debugApp(
          providers: buildClashProviders(
            _depsWithClient(client, sharedPreferences: prefs),
          ),
          sharedPreferences: prefs,
          syncController: controller,
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      expect(find.text('Sincronización online'), findsOneWidget);
      expect(find.text('Validar snapshot local'), findsOneWidget);
      expect(find.text('Descargar partida online'), findsOneWidget);
      expect(find.text('Subir partida local actual'), findsOneWidget);
      expect(find.text('Server revision conocida'), findsOneWidget);
      expect(controller.lastValidateResult, isNull);
      expect(controller.lastPullResult, isNull);
      expect(controller.lastPushResult, isNull);

      await _tapSyncAction(tester, 'Validar snapshot local');
      expect(find.text('Correcto'), findsWidgets);

      await _tapSyncAction(tester, 'Descargar partida online');
      expect(find.text('No hay partida online todavía'), findsOneWidget);

      await _tapSyncAction(tester, 'Subir partida local actual');
      expect(find.text('¿Subir partida local?'), findsNothing);
      expect(controller.knownServerRevision, 1);

      await _tapSyncAction(tester, 'Descargar partida online');
      expect(controller.lastPullResult?.isSuccess, isTrue);
      expect(controller.lastPullResult?.serverRevision, 1);

      await _tapSyncAction(tester, 'Subir partida local actual');
      expect(find.text('¿Subir partida local?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(client.serverRevision, 1);

      await _tapSyncAction(tester, 'Subir partida local actual');
      await tester.tap(find.text('Subir'));
      await tester.pumpAndSettle();
      expect(controller.knownServerRevision, 2);

      controller.knownServerRevision = 1;
      await _tapSyncAction(tester, 'Subir partida local actual');
      await tester.tap(find.text('Subir'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Conflicto de revisión'), findsOneWidget);

      final applier = _CountingApplier(prefs: prefs);
      final applyController = _syncController(client, applier: applier);
      addTearDown(applyController.dispose);

      await tester.pumpWidget(
        _debugApp(
          providers: buildClashProviders(
            _depsWithClient(client, sharedPreferences: prefs),
          ),
          sharedPreferences: prefs,
          syncController: applyController,
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      final applyFinder = find.widgetWithText(
        OutlinedButton,
        'Aplicar partida online a este dispositivo',
      );
      expect(tester.widget<OutlinedButton>(applyFinder).onPressed, isNull);

      await _tapSyncAction(tester, 'Subir partida local actual');
      await tester.tap(find.text('Subir'));
      await tester.pumpAndSettle();
      await _tapSyncAction(tester, 'Descargar partida online');

      expect(applyController.canApplyPendingRemote, isTrue);
      expect(tester.widget<OutlinedButton>(applyFinder).onPressed, isNotNull);

      await _tapSyncWidget(tester, applyFinder);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(applier.applyCalls, 0);

      await _tapSyncWidget(tester, applyFinder);
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(applier.applyCalls, 1);
      expect(find.text('Aplicada correctamente'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashProviderDependencies _depsWithClient(
  ClashSyncClient client, {
  SharedPreferences? sharedPreferences,
}) {
  final deps = testClashProviderDependencies();
  return ClashProviderDependencies(
    lineupsBackend: deps.lineupsBackend,
    collectionBackend: deps.collectionBackend,
    expMaterialInventoryBackend: deps.expMaterialInventoryBackend,
    expMaterialsRepository: deps.expMaterialsRepository,
    techniqueBookInventoryBackend: deps.techniqueBookInventoryBackend,
    techniqueBooksRepository: deps.techniqueBooksRepository,
    evolutionMaterialInventoryBackend: deps.evolutionMaterialInventoryBackend,
    evolutionMaterialsRepository: deps.evolutionMaterialsRepository,
    storyProgressBackend: deps.storyProgressBackend,
    gachaDailyBackend: deps.gachaDailyBackend,
    gachaHistoryBackend: deps.gachaHistoryBackend,
    gachaPityBackend: deps.gachaPityBackend,
    dailyMissionsBackend: deps.dailyMissionsBackend,
    achievementsBackend: deps.achievementsBackend,
    weeklyMissionsBackend: deps.weeklyMissionsBackend,
    newsReadBackend: deps.newsReadBackend,
    giftsBackend: deps.giftsBackend,
    characterEventsBackend: deps.characterEventsBackend,
    gachaTicketInventoryBackend: deps.gachaTicketInventoryBackend,
    gachaTicketRepository: deps.gachaTicketRepository,
    rewardHistoryBackend: deps.rewardHistoryBackend,
    sharedPreferences: sharedPreferences,
    syncClientOverride: client,
  );
}

ClashSyncSnapshot _validSnapshot() {
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

class _StubSnapshotBuilder extends ClashSyncSnapshotBuilder {
  _StubSnapshotBuilder(this._snapshot)
    : super(dependencies: const ClashSyncSnapshotBuilderDependencies());

  final ClashSyncSnapshot _snapshot;

  @override
  Future<ClashSyncSnapshot> build() async => _snapshot;
}

class _CountingApplier extends ClashSyncSnapshotApplier {
  _CountingApplier({
    required SharedPreferences prefs,
    ClashSyncApplyResult? result,
  }) : _result =
           result ??
           const ClashSyncApplyResult(
             status: ClashSyncApplyStatus.success,
             backupCreated: true,
           ),
       super(
         builder: _StubSnapshotBuilder(_validSnapshot()),
         validator: const ClashSyncSnapshotValidator(),
         dependencies: ClashSyncSnapshotApplierDependencies(
           sharedPreferences: prefs,
         ),
       );

  final ClashSyncApplyResult _result;
  int applyCalls = 0;

  @override
  Future<ClashSyncApplyResult> applyRemoteSnapshot(
    ClashSyncSnapshot remote, {
    int? serverRevision,
  }) async {
    applyCalls += 1;
    return _result;
  }
}
