import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/debug/data/clash_debug_sync_controller.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_online_claim_registrar.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_coordinator.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_builder.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_snapshot_validator.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_claim_api_client.dart';
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
        find.text('Registrar claims online').evaluate().isNotEmpty ||
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

Widget _debugApp({
  required List<SingleChildWidget> providers,
  required SharedPreferences sharedPreferences,
  required ClashDebugSyncController syncController,
  required Key screenKey,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ClashDebugScreen(
        key: screenKey,
        sharedPreferences: sharedPreferences,
        syncController: syncController,
      ),
    ),
  );
}

Future<ClashDebugSyncController> _controller({
  required SharedPreferences prefs,
  required FakeClashClaimApiClient claimClient,
  bool onlineClaimsEnabled = false,
}) async {
  final storage = ClashSyncSettingsStorage(sharedPreferences: prefs);
  if (onlineClaimsEnabled) {
    await storage.setOnlineClaimsEnabled(true);
  }
  final registrar = ClashOnlineClaimRegistrar(
    settingsStorage: storage,
    claimApiClient: claimClient,
  );
  return ClashDebugSyncController(
    coordinator: ClashSyncCoordinator(
      builder: _StubSnapshotBuilder(_validSnapshot()),
      validator: const ClashSyncSnapshotValidator(),
      client: FakeClashSyncClient(),
      now: () => _epoch,
    ),
    settingsStorage: storage,
    onlineClaimRegistrar: registrar,
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

  group('ClashDebugScreen online claims Fase 83', () {
    testWidgets('toggle, prueba manual y registro online', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final prefs = await _mockPrefs();
      final claimClient = FakeClashClaimApiClient();
      final controller = await _controller(
        prefs: prefs,
        claimClient: claimClient,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _debugApp(
          providers: buildClashProviders(_depsWithPrefs(prefs)),
          sharedPreferences: prefs,
          syncController: controller,
          screenKey: const ValueKey('online-claims-flow'),
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      expect(find.text('Registrar claims online'), findsOneWidget);
      expect(controller.onlineClaimsEnabled, isFalse);

      final switches = find.byType(Switch);
      await tester.tap(switches.at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.onlineClaimsEnabled, isTrue);
      expect(claimClient.submitCalls, 0);

      await tester.ensureVisible(find.text('Probar registro de claim online'));
      await tester.tap(find.text('Probar registro de claim online'));
      await tester.pump();

      expect(claimClient.submitCalls, 1);
      expect(find.textContaining('Claim aceptado'), findsOneWidget);

      await tester.tap(find.text('Probar registro de claim online'));
      await tester.pump();

      expect(claimClient.submitCalls, 2);
      expect(find.textContaining('Claim ya procesado'), findsOneWidget);

      await controller.setOnlineClaimsEnabled(false);
      await tester.pump();

      await tester.tap(find.text('Probar registro de claim online'));
      await tester.pump();

      expect(claimClient.submitCalls, 2);
      expect(find.text('Registro online desactivado'), findsOneWidget);
    });
  });
}

final _epoch = DateTime.utc(2026, 6, 20, 12);

ClashProviderDependencies _depsWithPrefs(SharedPreferences prefs) {
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
    sharedPreferences: prefs,
    syncClientOverride: deps.syncClientOverride,
  );
}

ClashSyncSnapshot _validSnapshot() {
  return ClashSyncSnapshot(
    generatedAt: _epoch,
    schemaVersion: 1,
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
