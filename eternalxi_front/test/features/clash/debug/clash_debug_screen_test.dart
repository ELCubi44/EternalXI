import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/debug/presentation/clash_debug_screen.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../di/clash_providers_test.dart';

Future<SharedPreferences> _mockPrefs() async {
  return SharedPreferences.getInstance();
}

Future<void> _pumpUntilDebugLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 120; i++) {
    if (find.text('Sincronización online').evaluate().isNotEmpty ||
        find.text('Almacenamiento local').evaluate().isNotEmpty ||
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
  SharedPreferences? sharedPreferences,
  Key? screenKey,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: ClashDebugScreen(
        key: screenKey ?? ValueKey(sharedPreferences?.hashCode ?? providers),
        sharedPreferences: sharedPreferences,
      ),
    ),
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

  group('ClashDebugScreen Fase 61', () {
    testWidgets('carga diagnóstico, datos clave y ruta interna', (
      tester,
    ) async {
      final prefs = await _mockPrefs();
      await tester.pumpWidget(
        _debugApp(
          providers: buildClashProviders(testClashProviderDependencies()),
          sharedPreferences: prefs,
          screenKey: const ValueKey('debug-initial'),
        ),
      );
      await _pumpUntilDebugLoaded(tester);

      expect(find.text('Diagnóstico Clash'), findsOneWidget);
      expect(find.text('Sincronización online'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Almacenamiento local'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Almacenamiento local'), findsOneWidget);
      expect(find.text('Schema version'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Historial recompensas'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Historial recompensas'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Cartas únicas'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cartas únicas'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Monedas'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Monedas'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Materiales EXP'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Materiales EXP'), findsOneWidget);
      expect(find.textContaining('Reset'), findsNothing);
      expect(find.textContaining('Delete'), findsNothing);
      expect(find.textContaining('Clear'), findsNothing);
      expect(find.textContaining('Borrar'), findsNothing);
      expect(find.byType(FilledButton), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final historyBackend = InMemoryClashRewardHistoryBackend();
      final historyRepository = ClashRewardHistoryRepository(
        storage: historyBackend,
      );
      await historyRepository.recordGrant(
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: 'gift-1',
        title: 'Recompensa',
        result: ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(100)],
        ),
      );

      final historyProviders = buildClashProviders(
        testClashProviderDependencies(),
      );
      historyProviders.add(
        Provider<ClashRewardHistoryRepository>.value(value: historyRepository),
      );

      await tester.pumpWidget(
        _debugApp(
          providers: historyProviders,
          sharedPreferences: prefs,
          screenKey: const ValueKey('debug-history'),
        ),
      );
      await _pumpUntilDebugLoaded(tester);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Historial recompensas'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Historial recompensas'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final collectionBackend = InMemoryClashPlayerCollectionBackend();
      await collectionBackend.writeSnapshot(
        ClashPlayerCollectionSnapshot(
          ownedCardIds: {'card-a', 'card-b'},
          cardProgress: {
            'card-a': const ClashCardProgress(
              cardId: 'card-a',
              currentLevel: 1,
              currentExperience: 0,
              techniqueLevels: {},
              duplicateCopies: 2,
            ),
          },
        ),
      );

      final deps = testClashProviderDependencies();
      final collectionProviders = buildClashProviders(
        ClashProviderDependencies(
          lineupsBackend: deps.lineupsBackend,
          collectionBackend: collectionBackend,
          expMaterialInventoryBackend: deps.expMaterialInventoryBackend,
          expMaterialsRepository: deps.expMaterialsRepository,
          techniqueBookInventoryBackend: deps.techniqueBookInventoryBackend,
          techniqueBooksRepository: deps.techniqueBooksRepository,
          evolutionMaterialInventoryBackend:
              deps.evolutionMaterialInventoryBackend,
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
          syncClientOverride: deps.syncClientOverride,
        ),
      );

      await tester.pumpWidget(
        _debugApp(
          providers: collectionProviders,
          sharedPreferences: prefs,
          screenKey: const ValueKey('debug-collection'),
        ),
      );
      await _pumpUntilDebugLoaded(tester);
      await tester.scrollUntilVisible(
        find.text('Cartas únicas'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Cartas únicas'), findsOneWidget);
      expect(find.text('2'), findsWidgets);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.clashDebug,
            builder: (context, state) => MultiProvider(
              providers: buildClashProviders(testClashProviderDependencies()),
              child: ClashDebugScreen(sharedPreferences: prefs),
            ),
          ),
        ],
        initialLocation: AppRoutes.clashDebug,
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          routerConfig: router,
        ),
      );
      await _pumpUntilDebugLoaded(tester);
      expect(find.text('Diagnóstico Clash'), findsOneWidget);
    });
  });
}
