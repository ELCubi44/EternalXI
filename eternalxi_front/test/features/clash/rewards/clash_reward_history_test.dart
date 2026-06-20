import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/presentation/clash_reward_history_tile.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_chip.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../cards/clash_test_support.dart';

Widget _localizedApp({
  required Widget child,
  required List<SingleChildWidget> providers,
}) {
  return MultiProvider(
    providers: providers,
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashRewardHistoryRepository Fase 60', () {
    test('recordGrant persiste entrada', () async {
      final backend = InMemoryClashRewardHistoryBackend();
      final repository = ClashRewardHistoryRepository(storage: backend);

      await repository.recordGrant(
        sourceType: ClashRewardHistorySourceType.achievement,
        sourceId: 'ach-1',
        title: 'Recompensa recibida',
        result: ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(500)],
        ),
      );

      final entries = repository.loadEntries();
      expect(entries, hasLength(1));
      expect(
        entries.first.sourceType,
        ClashRewardHistorySourceType.achievement,
      );
      expect(entries.first.sourceId, 'ach-1');
    });
  });

  group('ClashRewardFeedback history Fase 60', () {
    testWidgets('gift claim registra historial', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      final historyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashGiftsRepository>.value(value: setup.gifts),
            Provider<ClashRewardHistoryRepository>.value(
              value: historyRepository,
            ),
          ],
          child: const ClashGiftsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reclamar todos'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      expect(historyRepository.loadEntries(), isNotEmpty);
      expect(
        historyRepository.loadEntries().first.sourceType,
        ClashRewardHistorySourceType.gift,
      );
    });

    testWidgets('shop purchase success registra historial', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final shopRepository = await createTestShopRepository(initialCoins: 1500);
      final historyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashShopRepository>.value(value: shopRepository),
            Provider<ClashRewardHistoryRepository>.value(
              value: historyRepository,
            ),
          ],
          child: const ClashShopScreen(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Comprar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprar').last);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await Future<void>.delayed(Duration.zero);
      });

      expect(historyRepository.loadEntries(), isNotEmpty);
      expect(
        historyRepository.loadEntries().first.sourceType,
        ClashRewardHistorySourceType.shop,
      );
    });

    test('event completion registra historial sin duplicar source', () async {
      final backend = InMemoryClashRewardHistoryBackend();
      final repository = ClashRewardHistoryRepository(storage: backend);

      await repository.recordGrant(
        sourceType: ClashRewardHistorySourceType.event,
        sourceId: 'mika:stage-1',
        title: 'Recompensa first clear',
        result: ClashRewardFeedback.fromCharacterEventReward(
          const ClashCharacterEventReward(gems: 2),
        ),
      );

      final entries = repository.loadEntries();
      expect(entries, hasLength(1));
      expect(entries.first.sourceId, 'mika:stage-1');
    });

    test('shop grantFailed registra fallo controlado', () async {
      final historyRepository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await historyRepository.recordFailure(
        sourceType: ClashRewardHistorySourceType.shop,
        sourceId: 'prod-1',
        title: 'No se pudieron entregar las recompensas',
      );

      final entries = historyRepository.loadEntries();
      expect(entries, hasLength(1));
      expect(entries.first.isFailure, isTrue);
      expect(entries.first.sourceType, ClashRewardHistorySourceType.shop);
    });
  });

  group('ClashRewardHistoryScreen Fase 60', () {
    testWidgets('muestra empty state', (tester) async {
      final repository = ClashRewardHistoryRepository(
        storage: InMemoryClashRewardHistoryBackend(),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashRewardHistoryRepository>.value(value: repository),
          ],
          child: const ClashRewardHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Historial de recompensas'), findsOneWidget);
      expect(find.text('Aún no hay recompensas registradas.'), findsOneWidget);
    });

    testWidgets('muestra rewards con ClashRewardList', (tester) async {
      final backend = InMemoryClashRewardHistoryBackend();
      final repository = ClashRewardHistoryRepository(storage: backend);
      await repository.recordGrant(
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: 'gift-1',
        title: 'Recompensa recibida',
        result: ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(100), ClashReward.gems(2)],
        ),
      );

      await tester.pumpWidget(
        _localizedApp(
          providers: [
            Provider<ClashRewardHistoryRepository>.value(value: repository),
          ],
          child: const ClashRewardHistoryScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClashRewardHistoryTile), findsOneWidget);
      expect(find.byType(ClashRewardChip), findsWidgets);
      expect(find.textContaining('Monedas'), findsWidgets);
    });
  });
}
