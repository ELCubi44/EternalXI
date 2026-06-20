import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_metadata_storage.dart';
import 'package:eternal_xi/features/clash/sync/data/fake_clash_sync_client.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_metadata.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_result.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_status_badge_kind.dart';
import 'package:eternal_xi/features/clash/sync/presentation/clash_sync_status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/clash_providers_test.dart';
import '../responsive/clash_responsive_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final epoch = DateTime.utc(2026, 6, 20, 12);

  group('ClashSyncStatusBadgePresentation Fase 78', () {
    test('sin metadata resuelve notPrepared', () {
      expect(
        ClashSyncStatusBadgePresentation.resolve(const ClashSyncMetadata()),
        ClashSyncStatusBadgeKind.notPrepared,
      );
    });

    test('metadata sincronizada resuelve synced', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        ClashSyncMetadata(
          knownServerRevision: 2,
          lastSuccessfulSyncAt: epoch,
          lastStatus: 'success',
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.synced);
    });

    test('metadata con conflicto resuelve conflict', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        const ClashSyncMetadata(
          knownServerRevision: 2,
          lastStatus: 'conflict',
          lastConflictServerRevision: 3,
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.conflict);
    });

    test('metadata unavailable resuelve error', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        const ClashSyncMetadata(
          lastStatus: 'unavailable',
          lastErrorCode: 'network_error',
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.error);
    });

    test('metadata unauthorized resuelve error', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        const ClashSyncMetadata(
          lastStatus: 'unavailable',
          lastErrorCode: 'unauthorized',
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.error);
    });

    test('metadata con backup resuelve backupAvailable', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        const ClashSyncMetadata(
          knownServerRevision: 1,
          lastStatus: 'success',
          hasLocalBackup: true,
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.backupAvailable);
    });

    test('metadata con remoto pendiente resuelve pendingLocal', () {
      final kind = ClashSyncStatusBadgePresentation.resolve(
        const ClashSyncMetadata(
          knownServerRevision: 2,
          lastStatus: 'success',
          hasPendingRemoteSnapshot: true,
        ),
      );

      expect(kind, ClashSyncStatusBadgeKind.pendingLocal);
    });
  });

  group('ClashSyncStatusBadge Fase 78', () {
    Future<void> _pumpBadgeApp(
      WidgetTester tester, {
      required ClashSyncMetadata metadata,
      VoidCallback? onTap,
    }) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: ClashSyncStatusBadge(metadata: metadata, onTap: onTap),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('muestra Sin preparar online sin metadata', (tester) async {
      await _pumpBadgeApp(tester, metadata: const ClashSyncMetadata());

      expect(find.text('Sin preparar online'), findsOneWidget);
      expect(find.text('Ver diagnóstico'), findsOneWidget);
    });

    testWidgets('muestra revision y ultimo sync cuando existe', (tester) async {
      await _pumpBadgeApp(
        tester,
        metadata: ClashSyncMetadata(
          knownServerRevision: 3,
          lastSuccessfulSyncAt: epoch,
          lastStatus: 'success',
        ),
      );

      expect(find.text('Sincronizado'), findsOneWidget);
      expect(find.textContaining('Rev. 3'), findsOneWidget);
      expect(find.textContaining('Sync 20/06'), findsOneWidget);
    });

    testWidgets('muestra conflicto si metadata tiene conflict', (tester) async {
      await _pumpBadgeApp(
        tester,
        metadata: const ClashSyncMetadata(
          lastStatus: 'conflict',
          lastConflictServerRevision: 4,
        ),
      );

      expect(find.text('Conflicto de sync'), findsOneWidget);
      expect(find.textContaining('Remota rev. 4'), findsOneWidget);
    });

    testWidgets('muestra error si metadata unavailable', (tester) async {
      await _pumpBadgeApp(
        tester,
        metadata: const ClashSyncMetadata(
          lastStatus: 'unavailable',
          lastMessage: 'Servicio caído',
        ),
      );

      expect(find.text('Error de sync'), findsOneWidget);
      expect(find.textContaining('Servicio caído'), findsOneWidget);
    });

    testWidgets('muestra backup disponible si hasLocalBackup', (tester) async {
      await _pumpBadgeApp(
        tester,
        metadata: const ClashSyncMetadata(
          knownServerRevision: 1,
          lastStatus: 'success',
          hasLocalBackup: true,
        ),
      );

      expect(find.text('Backup disponible'), findsOneWidget);
    });

    testWidgets('tap navega a /clash/debug', (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: ClashSyncStatusBadge(
                metadata: const ClashSyncMetadata(),
                onTap: () => context.push(AppRoutes.clashDebug),
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

      await tester.tap(find.text('Sin preparar online'));
      await tester.pumpAndSettle();

      expect(find.text('DEBUG_ROUTE'), findsOneWidget);
    });

    testWidgets('construir Clash Home no ejecuta HTTP/sync', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();
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
      expect(find.text('Sin preparar online'), findsOneWidget);
    });

    testWidgets('responsive smallPhone sin overflow', (tester) async {
      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-06-11T10:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();

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
          ],
          child: const ClashHomeScreen(),
        );
      }, asyncWait: const Duration(milliseconds: 600));
      await pumpUntilSettled(tester);
      expectNoFlutterLayoutErrors(tester, pumpResult: result);
      expect(find.text('Sin preparar online'), findsOneWidget);
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
