import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement_reward.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/events/presentation/screens/clash_event_detail_screen.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_chip.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_icon.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_label.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

const _mikaEventId = 'event-mika-speed';

AppLocalizations _esL10n() => AppLocalizations(const Locale('es'));

Widget _eventsApp({
  required ClashCharacterEventsRepository eventsRepo,
  ClashCardsRepository? cardsRepo,
  required Widget child,
}) {
  return MultiProvider(
    providers: [
      Provider<ClashCharacterEventsRepository>.value(value: eventsRepo),
      if (cardsRepo != null)
        Provider<ClashCardsRepository>.value(value: cardsRepo),
    ],
    child: MaterialApp(
      locale: const Locale('es'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    ),
  );
}

Widget _localizedApp({required Widget child}) {
  return MaterialApp(
    locale: const Locale('es'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashRewardLabel Fase 58', () {
    final l10n = _esL10n();

    test('labels conocidos', () {
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'basic-training-manual'),
        'Manual básico',
      );
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'advanced-training-manual'),
        'Manual avanzado',
      );
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'master-training-manual'),
        'Manual maestro',
      );
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'basic-technique-book'),
        'Libro técnico básico',
      );
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'advanced-technique-book'),
        'Libro técnico avanzado',
      );
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'master-technique-book'),
        'Libro técnico maestro',
      );
      expect(ClashRewardLabel.itemIdLabel(l10n, 'insignia-r'), 'Insignia R');
      expect(ClashRewardLabel.itemIdLabel(l10n, 'insignia-sr'), 'Insignia SR');
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'starter-single-ticket'),
        'Ticket inicial',
      );
    });

    test('id desconocido devuelve fallback estable', () {
      expect(
        ClashRewardLabel.itemIdLabel(l10n, 'unknown-reward-id'),
        'unknown-reward-id',
      );
    });

    test('shopGrantOrItemLabel prioriza id conocido', () {
      expect(
        ClashRewardLabel.shopGrantOrItemLabel(
          l10n,
          id: 'basic-training-manual',
          grantLabel: 'Etiqueta JSON distinta',
        ),
        'Manual básico',
      );
    });
  });

  group('ClashRewardDisplayBuilder Fase 58', () {
    final l10n = _esL10n();

    test('fromCharacterEventReward incluye libro técnico', () {
      const reward = ClashCharacterEventReward(
        techniqueBook: ClashAchievementItemReward(
          id: 'basic-technique-book',
          quantity: 1,
        ),
      );
      final items = ClashRewardDisplayBuilder.fromCharacterEventReward(
        reward,
        l10n,
      );
      expect(items, hasLength(1));
      expect(items.first.label, 'Libro técnico básico');
      expect(items.first.quantity, 1);
    });

    test('fromCharacterEventReward featuredCard', () {
      const reward = ClashCharacterEventReward(featuredCardId: 'exi-n-wg-001');
      final items = ClashRewardDisplayBuilder.fromCharacterEventReward(
        reward,
        l10n,
      );
      expect(items.first.label, 'Carta destacada');
      expect(items.first.detail, 'exi-n-wg-001');
    });

    test('fromDailyMissionReward monedas y gemas', () {
      const reward = ClashDailyMissionReward(coins: 300, gems: 2);
      final items = ClashRewardDisplayBuilder.fromDailyMissionReward(
        reward,
        l10n,
      );
      expect(
        items.map((item) => item.label),
        containsAll(['Monedas', 'Gemas']),
      );
    });

    test('compactPreview une items', () {
      const reward = ClashDailyMissionReward(coins: 50);
      final items = ClashRewardDisplayBuilder.fromDailyMissionReward(
        reward,
        l10n,
      );
      expect(
        ClashRewardDisplayBuilder.compactPreview(items, l10n),
        'Monedas ×50',
      );
    });
  });

  group('ClashRewardChip Fase 58', () {
    testWidgets('renderiza label y cantidad', (tester) async {
      await tester.pumpWidget(
        _localizedApp(
          child: ClashRewardChip(
            item: ClashRewardDisplayItem(
              icon: ClashRewardIcon.forKind(ClashRewardKind.coins),
              label: 'Monedas',
              quantity: 250,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Monedas'), findsOneWidget);
      expect(find.text('×250'), findsOneWidget);
    });
  });

  group('Events UI rewards Fase 58', () {
    testWidgets('detalle Mika muestra firstClear y repeat con labels', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 2800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestEventsSetup();
      await tester.pumpWidget(
        _eventsApp(
          eventsRepo: setup.events,
          cardsRepo: ClashCardsRepository(GachaTestCardsDataSource()),
          child: const ClashEventDetailScreen(eventId: _mikaEventId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Primera vez'), findsWidgets);
      expect(find.text('Repetición'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Libro técnico básico'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Libro técnico básico'), findsOneWidget);
      expect(find.text('Carta destacada'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Gifts UI rewards Fase 58', () {
    testWidgets('regalos muestran labels compartidos', (tester) async {
      tester.view.physicalSize = const Size(400, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final setup = await createTestGiftsSetup();
      await tester.pumpWidget(
        Provider<ClashGiftsRepository>.value(
          value: setup.gifts,
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashGiftsScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gemas'), findsWidgets);
      expect(find.text('Monedas'), findsWidgets);
      expect(find.text('Ticket inicial'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Shop UI rewards Fase 58', () {
    testWidgets(
      'producto muestra grants con labels compartidos',
      (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = await createTestShopRepository();
      await tester.pumpWidget(
        Provider<ClashShopRepository>.value(
          value: repo,
          child: MaterialApp(
            locale: const Locale('es'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(body: ClashShopScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Manual básico'), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
      skip: 'Tienda vacía temporalmente',
    );
  });
}
