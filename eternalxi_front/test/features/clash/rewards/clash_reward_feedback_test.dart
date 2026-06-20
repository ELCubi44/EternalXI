import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_repository.dart';
import 'package:eternal_xi/features/clash/gifts/presentation/screens/clash_gifts_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_chip.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback_sheet.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback_message.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/presentation/screens/clash_shop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

AppLocalizations _esL10n() => AppLocalizations(const Locale('es'));

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

  group('ClashRewardFeedback.buildMessage Fase 59', () {
    final l10n = _esL10n();

    test('éxito simple con una recompensa', () {
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(100)],
          coinsAdded: 100,
        ),
      );
      expect(message.kind, ClashRewardFeedbackKind.success);
      expect(message.title, 'Recompensa recibida');
      expect(message.items, hasLength(1));
      expect(message.compactSummary, 'Monedas ×100');
    });

    test('éxito con varias recompensas', () {
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardGrantResult(
          grantedRewards: [
            ClashReward.coins(100),
            ClashReward.gems(2),
            ClashReward.expMaterial('basic-training-manual', 1),
          ],
        ),
      );
      expect(message.title, 'Recompensas recibidas');
      expect(message.items, hasLength(3));
      expect(message.useCompactPresentation, isFalse);
    });

    test('parcial con failedRewards', () {
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardGrantResult(
          grantedRewards: [ClashReward.gems(1)],
          failedRewards: [
            ClashFailedReward(
              reward: ClashReward.coins(50),
              error: 'grant_failed',
            ),
          ],
        ),
      );
      expect(message.kind, ClashRewardFeedbackKind.partial);
      expect(message.title, 'Algunas recompensas no se pudieron entregar');
      expect(message.items, hasLength(1));
    });

    test('fallo total sin concesiones', () {
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardGrantResult.allFailed([ClashReward.gems(1)]),
      );
      expect(message.kind, ClashRewardFeedbackKind.failure);
      expect(message.title, 'No se pudieron entregar las recompensas');
      expect(message.items, isEmpty);
    });

    test('duplicado de carta con label correcto', () {
      final items = ClashRewardDisplayBuilder.fromGrantResult(
        ClashRewardGrantResult(
          grantedRewards: [
            ClashReward.featuredCard('exi-n-wg-001', asDuplicateOnly: true),
          ],
          duplicateCardIds: ['exi-n-wg-001'],
        ),
        l10n,
      );
      expect(items.any((item) => item.label == 'Copia duplicada'), isTrue);
    });

    test('evento firstClear usa título personalizado', () {
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardFeedback.fromCharacterEventReward(
          const ClashCharacterEventReward(coins: 200, gems: 1),
        ),
        successTitle: l10n.clashEventsRewardFirstClear,
      );
      expect(message.title, '¡Primera victoria!');
    });
  });

  group('ClashRewardFeedback UI Fase 59', () {
    testWidgets('ClashRewardFeedbackBody renderiza título e items', (
      tester,
    ) async {
      final l10n = _esL10n();
      final message = ClashRewardFeedback.buildMessage(
        l10n,
        ClashRewardGrantResult(grantedRewards: [ClashReward.coins(50)]),
      );

      await tester.pumpWidget(
        _localizedApp(child: ClashRewardFeedbackBody(message: message)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recompensa recibida'), findsOneWidget);
      expect(find.text('Monedas'), findsOneWidget);
      expect(find.byType(ClashRewardChip), findsOneWidget);
    });

    testWidgets('gift claim muestra feedback compartido', (tester) async {
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

      await tester.tap(find.text('Reclamar todos'));
      await tester.pumpAndSettle();

      expect(find.text('Recompensas recibidas'), findsOneWidget);
      expect(find.text('Monedas'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shop purchase success muestra feedback compartido', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final repo = await createTestShopRepository(initialCoins: 1500);
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

      await tester.tap(find.text('Comprar').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comprar').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('Manual básico'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
