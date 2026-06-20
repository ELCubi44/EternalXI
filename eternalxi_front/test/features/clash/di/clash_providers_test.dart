import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gifts/data/clash_gifts_storage.dart';
import 'package:eternal_xi/features/clash/home/presentation/clash_home_screen.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/team/data/datasources/clash_lineups_local_storage.dart';
import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../cards/clash_test_support.dart';

ClashProviderDependencies _testClashProviderDependencies() {
  final expMaterialsRepository = createTestExpMaterialsRepository();
  final techniqueBooksRepository = createTestTechniqueBooksRepository();
  final evolutionMaterialsRepository = createTestEvolutionMaterialsRepository();
  final gachaTicketRepository = createTestTicketRepository();

  return ClashProviderDependencies(
    lineupsBackend: InMemoryClashLineupsBackend(),
    collectionBackend: InMemoryClashPlayerCollectionBackend(),
    expMaterialInventoryBackend: InMemoryClashExpMaterialInventoryBackend(),
    expMaterialsRepository: expMaterialsRepository,
    techniqueBookInventoryBackend: InMemoryClashTechniqueBookInventoryBackend(),
    techniqueBooksRepository: techniqueBooksRepository,
    evolutionMaterialInventoryBackend:
        InMemoryClashEvolutionMaterialInventoryBackend(),
    evolutionMaterialsRepository: evolutionMaterialsRepository,
    storyProgressBackend: InMemoryClashStoryProgressBackend(),
    gachaDailyBackend: InMemoryClashGachaDailyBackend(),
    gachaHistoryBackend: InMemoryClashGachaHistoryBackend(),
    gachaPityBackend: InMemoryClashGachaPityBackend(),
    dailyMissionsBackend: InMemoryClashDailyMissionsBackend(),
    achievementsBackend: InMemoryClashAchievementsBackend(),
    weeklyMissionsBackend: InMemoryClashWeeklyMissionsBackend(),
    newsReadBackend: InMemoryClashNewsReadBackend(),
    giftsBackend: InMemoryClashGiftsBackend(),
    characterEventsBackend: InMemoryClashCharacterEventsBackend(),
    gachaTicketInventoryBackend: InMemoryClashGachaTicketInventoryBackend(),
    gachaTicketRepository: gachaTicketRepository,
    rewardHistoryBackend: InMemoryClashRewardHistoryBackend(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('buildClashProviders', () {
    test('devuelve lista no vacía con providers Clash', () {
      final providers = buildClashProviders(_testClashProviderDependencies());
      expect(providers, isNotEmpty);
      expect(providers.length, greaterThanOrEqualTo(40));
    });

    testWidgets('permite renderizar ClashHome con providers del builder', (
      tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: buildClashProviders(_testClashProviderDependencies()),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ClashHomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ClashHomeScreen), findsOneWidget);
    });
  });
}
