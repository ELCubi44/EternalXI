import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_pending_sync_notice_presentation.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/presentation/clash_pending_sync_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/clash_providers_test.dart';
import '../responsive/clash_responsive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashPendingSyncNoticePresentation Fase 80', () {
    test('no muestra si no hay pendingRemoteSnapshot', () {
      expect(
        ClashPendingSyncNoticePresentation.shouldShow(
          hasPendingRemoteSnapshot: false,
          knownServerRevision: 2,
          dismissedRevision: null,
        ),
        isFalse,
      );
    });

    test('muestra si pending y revision no descartada', () {
      expect(
        ClashPendingSyncNoticePresentation.shouldShow(
          hasPendingRemoteSnapshot: true,
          knownServerRevision: 3,
          dismissedRevision: null,
        ),
        isTrue,
      );
    });

    test('no muestra si revision descartada coincide', () {
      expect(
        ClashPendingSyncNoticePresentation.shouldShow(
          hasPendingRemoteSnapshot: true,
          knownServerRevision: 3,
          dismissedRevision: 3,
        ),
        isFalse,
      );
    });

    test('vuelve a mostrar si revision cambia', () {
      expect(
        ClashPendingSyncNoticePresentation.shouldShow(
          hasPendingRemoteSnapshot: true,
          knownServerRevision: 4,
          dismissedRevision: 3,
        ),
        isTrue,
      );
    });

    test('no muestra si revision conocida invalida', () {
      expect(
        ClashPendingSyncNoticePresentation.shouldShow(
          hasPendingRemoteSnapshot: true,
          knownServerRevision: null,
          dismissedRevision: null,
        ),
        isFalse,
      );
    });
  });

  group('ClashPendingSyncNotice Fase 80', () {
    Future<void> _pumpNoticeApp(
      WidgetTester tester, {
      required ClashSyncMetadata metadata,
      required SharedPreferences prefs,
      VoidCallback? onReview,
      VoidCallback? onDismiss,
    }) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>(
              create: (_) => ClashSyncMetadataStorage(sharedPreferences: prefs),
            ),
            Provider<ClashSyncSettingsStorage>(
              create: (_) => ClashSyncSettingsStorage(sharedPreferences: prefs),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: ClashPendingSyncNotice(
                metadata: metadata,
                onReview: onReview ?? () {},
                onDismiss: onDismiss ?? () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra titulo y cuerpo con pending', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await _pumpNoticeApp(
        tester,
        prefs: prefs,
        metadata: const ClashSyncMetadata(
          knownServerRevision: 2,
          hasPendingRemoteSnapshot: true,
        ),
      );

      expect(find.text('Partida online disponible'), findsOneWidget);
      expect(
        find.text('Hay una partida online pendiente de revisar.'),
        findsOneWidget,
      );
      expect(find.text('Revisar'), findsOneWidget);
    });

    testWidgets('boton Revisar navega a /clash/debug', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ClashPendingSyncNotice(
                metadata: const ClashSyncMetadata(
                  knownServerRevision: 2,
                  hasPendingRemoteSnapshot: true,
                ),
                onReview: () => context.push(AppRoutes.clashDebug),
                onDismiss: () {},
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.clashDebug,
            builder: (context, state) =>
                const Scaffold(body: Text('DEBUG_ROUTE')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Revisar'));
      await tester.pumpAndSettle();

      expect(find.text('DEBUG_ROUTE'), findsOneWidget);
    });

    testWidgets('loader no muestra aviso sin pending', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final metadataStorage = ClashSyncMetadataStorage(
        sharedPreferences: prefs,
      );
      await metadataStorage.save(
        const ClashSyncMetadata(knownServerRevision: 1, lastStatus: 'success'),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>.value(value: metadataStorage),
            Provider<ClashSyncSettingsStorage>(
              create: (_) => ClashSyncSettingsStorage(sharedPreferences: prefs),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashPendingSyncNoticeLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partida online disponible'), findsNothing);
    });

    testWidgets('loader muestra aviso con pending no descartado', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final metadataStorage = ClashSyncMetadataStorage(
        sharedPreferences: prefs,
      );
      await metadataStorage.save(
        const ClashSyncMetadata(
          knownServerRevision: 5,
          hasPendingRemoteSnapshot: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>.value(value: metadataStorage),
            Provider<ClashSyncSettingsStorage>(
              create: (_) => ClashSyncSettingsStorage(sharedPreferences: prefs),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashPendingSyncNoticeLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partida online disponible'), findsOneWidget);
    });

    testWidgets('loader oculta si revision descartada coincide', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.syncPendingNoticeDismissedRevision: 5,
      });
      final prefs = await SharedPreferences.getInstance();
      final metadataStorage = ClashSyncMetadataStorage(
        sharedPreferences: prefs,
      );
      await metadataStorage.save(
        const ClashSyncMetadata(
          knownServerRevision: 5,
          hasPendingRemoteSnapshot: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>.value(value: metadataStorage),
            Provider<ClashSyncSettingsStorage>(
              create: (_) => ClashSyncSettingsStorage(sharedPreferences: prefs),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashPendingSyncNoticeLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partida online disponible'), findsNothing);
    });

    testWidgets('cerrar aviso guarda revision descartada', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsStorage = ClashSyncSettingsStorage(
        sharedPreferences: prefs,
      );
      final metadataStorage = ClashSyncMetadataStorage(
        sharedPreferences: prefs,
      );
      await metadataStorage.save(
        const ClashSyncMetadata(
          knownServerRevision: 7,
          hasPendingRemoteSnapshot: true,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>.value(value: metadataStorage),
            Provider<ClashSyncSettingsStorage>.value(value: settingsStorage),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashPendingSyncNoticeLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(settingsStorage.loadDismissedPendingRevision(), 7);
      expect(find.text('Partida online disponible'), findsNothing);
    });

    testWidgets('cerrar no borra metadata ni pendingRemoteSnapshot', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settingsStorage = ClashSyncSettingsStorage(
        sharedPreferences: prefs,
      );
      final metadataStorage = ClashSyncMetadataStorage(
        sharedPreferences: prefs,
      );
      await metadataStorage.save(
        const ClashSyncMetadata(
          knownServerRevision: 8,
          hasPendingRemoteSnapshot: true,
          lastStatus: 'success',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<ClashSyncMetadataStorage>.value(value: metadataStorage),
            Provider<ClashSyncSettingsStorage>.value(value: settingsStorage),
          ],
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashPendingSyncNoticeLoader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      final metadata = metadataStorage.load();
      expect(metadata.hasPendingRemoteSnapshot, isTrue);
      expect(metadata.knownServerRevision, 8);
      expect(settingsStorage.loadDismissedPendingRevision(), 8);
    });

    testWidgets('Home con pending no ejecuta HTTP por el aviso', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();
      await ClashSyncMetadataStorage(sharedPreferences: prefs).save(
        const ClashSyncMetadata(
          knownServerRevision: 2,
          hasPendingRemoteSnapshot: true,
        ),
      );

      final client = _CountingSyncClient();
      final baseDeps = testClashProviderDependencies();

      await tester.pumpWidget(
        MultiProvider(
          providers: buildClashProviders(
            ClashProviderDependencies(
              lineupsBackend: baseDeps.lineupsBackend,
              collectionBackend: baseDeps.collectionBackend,
              expMaterialInventoryBackend: baseDeps.expMaterialInventoryBackend,
              expMaterialsRepository: baseDeps.expMaterialsRepository,
              techniqueBookInventoryBackend:
                  baseDeps.techniqueBookInventoryBackend,
              techniqueBooksRepository: baseDeps.techniqueBooksRepository,
              evolutionMaterialInventoryBackend:
                  baseDeps.evolutionMaterialInventoryBackend,
              evolutionMaterialsRepository:
                  baseDeps.evolutionMaterialsRepository,
              storyProgressBackend: baseDeps.storyProgressBackend,
              gachaDailyBackend: baseDeps.gachaDailyBackend,
              gachaHistoryBackend: baseDeps.gachaHistoryBackend,
              gachaPityBackend: baseDeps.gachaPityBackend,
              dailyMissionsBackend: baseDeps.dailyMissionsBackend,
              achievementsBackend: baseDeps.achievementsBackend,
              weeklyMissionsBackend: baseDeps.weeklyMissionsBackend,
              newsReadBackend: baseDeps.newsReadBackend,
              giftsBackend: baseDeps.giftsBackend,
              characterEventsBackend: baseDeps.characterEventsBackend,
              gachaTicketInventoryBackend: baseDeps.gachaTicketInventoryBackend,
              gachaTicketRepository: baseDeps.gachaTicketRepository,
              rewardHistoryBackend: baseDeps.rewardHistoryBackend,
              sharedPreferences: prefs,
              syncClientOverride: client,
            ),
          ),
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const ClashHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(client.pullCalls, 0);
      expect(client.pushCalls, 0);
      expect(find.text('Partida online disponible'), findsOneWidget);
    });

    testWidgets('responsive smallPhone sin overflow con aviso', (tester) async {
      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();
      await ClashSyncMetadataStorage(sharedPreferences: prefs).save(
        const ClashSyncMetadata(
          knownServerRevision: 2,
          hasPendingRemoteSnapshot: true,
        ),
      );

      await resetResponsiveTestSurface(tester);
      configureClashResponsiveViewport(
        tester,
        ClashResponsiveViewports.smallPhone,
      );
      await applyClashResponsiveSurface(
        tester,
        ClashResponsiveViewports.smallPhone,
      );

      final result = await pumpResponsiveWidget(tester, () async {
        final deps = await createResponsiveHomeDeps();
        return clashResponsiveMaterialApp(
          providers: [
            ...responsiveHomeProviders(deps),
            Provider<ClashSyncMetadataStorage>(
              create: (_) => ClashSyncMetadataStorage(sharedPreferences: prefs),
            ),
            Provider<ClashSyncSettingsStorage>(
              create: (_) => ClashSyncSettingsStorage(sharedPreferences: prefs),
            ),
          ],
          child: const ClashHomeScreen(),
        );
      }, asyncWait: const Duration(milliseconds: 600));
      await pumpUntilSettled(tester);
      expectNoFlutterLayoutErrors(tester, pumpResult: result);
      expect(find.text('Partida online disponible'), findsOneWidget);
    });
  });
}

class _CountingSyncClient extends FakeClashSyncClient {
  int pullCalls = 0;
  int pushCalls = 0;

  @override
  Future<ClashSyncPullResult> pullSnapshot() async {
    pullCalls += 1;
    return super.pullSnapshot();
  }

  @override
  Future<ClashSyncPushResult> pushSnapshot(
    ClashSyncSnapshot snapshot, {
    int? expectedServerRevision,
  }) async {
    pushCalls += 1;
    return super.pushSnapshot(
      snapshot,
      expectedServerRevision: expectedServerRevision,
    );
  }
}
