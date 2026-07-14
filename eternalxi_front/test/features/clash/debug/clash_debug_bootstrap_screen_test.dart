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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      ClashSharedPreferencesKeys.schemaVersion: 1,
      ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
    });
  });

  group('ClashDebugScreen bootstrap Fase 77', () {
    testWidgets('bootstrap manual crea partida online', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await _mockPrefs();
      final client = FakeClashSyncClient();
      final controller = ClashDebugSyncController(
        coordinator: ClashSyncCoordinator(
          builder: _StubSnapshotBuilder(_validSnapshot()),
          validator: const ClashSyncSnapshotValidator(),
          client: client,
          now: () => _epoch,
        ),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: buildClashProviders(
            _depsWithClient(client, sharedPreferences: prefs),
          ),
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ClashDebugScreen(
              sharedPreferences: prefs,
              syncController: controller,
            ),
          ),
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      expect(find.text('Preparar partida online'), findsOneWidget);
      expect(controller.lastBootstrapResult, isNull);

      final bootstrapButton = find.text('Preparar partida online');
      await tester.ensureVisible(bootstrapButton);
      await tester.pumpAndSettle();
      await tester.tap(bootstrapButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Partida online creada'), findsOneWidget);
      expect(controller.lastBootstrapResult?.isRemoteCreated, isTrue);
      expect(client.serverRevision, 1);
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
    trialsBackend: deps.trialsBackend,
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
