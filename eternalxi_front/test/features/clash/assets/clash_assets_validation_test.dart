import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/help/presentation/screens/clash_help_topic_screen.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_ids.dart';
import 'package:flutter_test/flutter_test.dart';

import 'clash_assets_validation_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Set<String> cardIds;
  late Set<String> rivalTeamIds;
  late Set<String> bannerIds;
  late Set<String> expMaterialIds;
  late Set<String> techniqueBookIds;
  late Set<String> evolutionMaterialIds;
  late Set<String> ticketIds;
  late String chapterId;

  setUpAll(() async {
    final cardsJson = await loadClashAssetJson('assets/data/clash/cards.json');
    final cards = cardsJson['cards'] as List;
    cardIds = cards.map((c) => (c as Map)['id'].toString()).toSet();
    assertUniqueIds(cardIds, 'cards.json');

    for (final raw in cards) {
      final card = Map<String, dynamic>.from(raw as Map);
      final context = 'cards.${card['id']}';
      assertRequiredString(card, 'id', context);
      assertNonNegativeNumber(
        card['playerId'],
        'playerId',
        context,
        positive: true,
      );
      assertRequiredString(card, 'name', context);
      assertRequiredString(card, 'team', context);
      ClashRarity.fromJson(card['rarity']);
      ClashPlayerStyle.fromJson(card['style']);
      ClashPosition.fromJson(card['position']);
      assertNonNegativeNumber(card['level'], 'level', context, positive: true);
      assertRequiredString(card, 'basicPortraitPath', context);
      validateStats(Map<String, dynamic>.from(card['stats'] as Map), context);
      final techniques = card['superTechniques'] as List? ?? const [];
      for (final techniqueRaw in techniques) {
        validateSuperTechnique(
          Map<String, dynamic>.from(techniqueRaw as Map),
          '$context.superTechnique',
        );
      }
    }

    final expJson = await loadClashAssetJson(
      'assets/data/clash/exp_materials.json',
    );
    expMaterialIds = (expJson['materials'] as List)
        .map((m) => (m as Map)['id'].toString())
        .toSet();
    assertUniqueIds(expMaterialIds, 'exp_materials.json');
    expect(expMaterialIds, ClashRewardIds.expMaterials);

    final booksJson = await loadClashAssetJson(
      'assets/data/clash/technique_books.json',
    );
    techniqueBookIds = (booksJson['books'] as List)
        .map((b) => (b as Map)['id'].toString())
        .toSet();
    assertUniqueIds(techniqueBookIds, 'technique_books.json');
    expect(techniqueBookIds, ClashRewardIds.techniqueBooks);

    final evoJson = await loadClashAssetJson(
      'assets/data/clash/evolution_materials.json',
    );
    evolutionMaterialIds = (evoJson['materials'] as List)
        .map((m) => (m as Map)['id'].toString())
        .toSet();
    assertUniqueIds(evolutionMaterialIds, 'evolution_materials.json');
    expect(evolutionMaterialIds, ClashRewardIds.evolutionMaterials);

    final bannersJson = await loadClashAssetJson(
      'assets/data/clash/gacha_banners.json',
    );
    validateGachaRates(Map<String, dynamic>.from(bannersJson['rates'] as Map));
    final banners = bannersJson['banners'] as List;
    bannerIds = banners.map((b) => (b as Map)['id'].toString()).toSet();
    assertUniqueIds(bannerIds, 'gacha_banners.json');
    for (final raw in banners) {
      validateGachaBanner(
        Map<String, dynamic>.from(raw as Map),
        'gacha_banners.${(raw as Map)['id']}',
        cardIds: cardIds,
      );
    }

    final ticketsJson = await loadClashAssetJson(
      'assets/data/clash/gacha_tickets.json',
    );
    final tickets = ticketsJson['tickets'] as List;
    ticketIds = tickets.map((t) => (t as Map)['id'].toString()).toSet();
    assertUniqueIds(ticketIds, 'gacha_tickets.json');
    expect(ticketIds, ClashRewardIds.tickets);
    for (final raw in tickets) {
      validateGachaTicket(
        Map<String, dynamic>.from(raw as Map),
        'gacha_tickets.${(raw as Map)['id']}',
        bannerIds: bannerIds,
      );
    }

    final rivalsJson = await loadClashAssetJson(
      'assets/data/clash/rivals.json',
    );
    final rivals = rivalsJson['rivals'] as List;
    rivalTeamIds = rivals.map((r) => (r as Map)['id'].toString()).toSet();
    assertUniqueIds(rivalTeamIds, 'rivals.json');
    for (final raw in rivals) {
      final rival = Map<String, dynamic>.from(raw as Map);
      final teamId = rival['id'] as String;
      assertRequiredString(rival, 'name', 'rivals.$teamId');
      assertRequiredString(rival, 'description', 'rivals.$teamId');
      validateRivalLineup(rival['lineup7v7'] as List, teamId);
    }

    final sagasJson = await loadClashAssetJson(
      'assets/data/clash/story/sagas.json',
    );
    final sagas = sagasJson['sagas'] as List;
    assertUniqueIds(
      sagas.map((s) => (s as Map)['id'].toString()),
      'story/sagas.json',
    );

    final chapterJson = await loadClashAssetJson(
      'assets/data/clash/story/chapter_01.json',
    );
    final chapter = Map<String, dynamic>.from(chapterJson['chapter'] as Map);
    chapterId = chapter['id'] as String;
    assertRequiredString(chapter, 'title', 'story.chapter');
    final levels = chapter['levels'] as List;
    assertUniqueIds(
      levels.map((l) => (l as Map)['id'].toString()),
      'story/chapter_01.json levels',
    );
    for (final raw in levels) {
      final level = Map<String, dynamic>.from(raw as Map);
      final levelId = level['id'] as String;
      final context = 'story.level.$levelId';
      assertRequiredString(level, 'title', context);
      if (level['type'] == 'match') {
        final rivalId = level['rivalTeamId']?.toString() ?? '';
        expect(
          rivalTeamIds.contains(rivalId),
          isTrue,
          reason: '$context.rivalTeamId inexistente: $rivalId',
        );
      }
      if (level.containsKey('rewards')) {
        validateStoryReward(
          Map<String, dynamic>.from(level['rewards'] as Map),
          '$context.rewards',
          cardIds: cardIds,
        );
      }
      final objectives = level['matchObjectives'] as List? ?? const [];
      for (final objectiveRaw in objectives) {
        final objective = Map<String, dynamic>.from(objectiveRaw as Map);
        final objectiveId = objective['id'] as String;
        if (objective.containsKey('rewards')) {
          validateStoryReward(
            Map<String, dynamic>.from(objective['rewards'] as Map),
            '$context.objective.$objectiveId.rewards',
            cardIds: cardIds,
          );
        }
      }
    }

    for (final raw in sagas) {
      final saga = Map<String, dynamic>.from(raw as Map);
      final chapterIds = (saga['chapterIds'] as List? ?? const [])
          .map((id) => id.toString())
          .toList();
      expect(
        chapterIds.contains(chapterId),
        isTrue,
        reason: 'saga ${saga['id']} referencia capítulo inexistente',
      );
    }
  });

  test('shop_products.json grants y ids únicos', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/shop_products.json',
    );
    final products = json['products'] as List;
    assertUniqueIds(
      products.map((p) => (p as Map)['id'].toString()),
      'shop_products.json',
    );
    for (final raw in products) {
      final product = Map<String, dynamic>.from(raw as Map);
      final context = 'shop.${product['id']}';
      assertRequiredString(product, 'name', context);
      assertNonNegativeNumber(
        product['costCoins'],
        'costCoins',
        context,
        positive: true,
      );
      final grants = product['grants'] as List? ?? const [];
      expect(grants, isNotEmpty, reason: '$context.grants vacío');
      for (final grantRaw in grants) {
        validateShopGrant(
          Map<String, dynamic>.from(grantRaw as Map),
          '$context.grant',
        );
      }
    }
  });

  test('daily_missions.json rewards válidos', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/daily_missions.json',
    );
    final missions = json['missions'] as List;
    assertUniqueIds(
      missions.map((m) => (m as Map)['id'].toString()),
      'daily_missions.json',
    );
    for (final raw in missions) {
      final mission = Map<String, dynamic>.from(raw as Map);
      validateGrantReward(
        Map<String, dynamic>.from(mission['reward'] as Map),
        'daily.${mission['id']}.reward',
        cardIds: cardIds,
      );
    }
  });

  test('weekly_missions.json rewards válidos', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/weekly_missions.json',
    );
    final missions = json['missions'] as List;
    assertUniqueIds(
      missions.map((m) => (m as Map)['id'].toString()),
      'weekly_missions.json',
    );
    for (final raw in missions) {
      final mission = Map<String, dynamic>.from(raw as Map);
      validateGrantReward(
        Map<String, dynamic>.from(mission['reward'] as Map),
        'weekly.${mission['id']}.reward',
        cardIds: cardIds,
      );
    }
  });

  test('achievements.json rewards válidos', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/achievements.json',
    );
    final achievements = json['achievements'] as List;
    assertUniqueIds(
      achievements.map((a) => (a as Map)['id'].toString()),
      'achievements.json',
    );
    for (final raw in achievements) {
      final achievement = Map<String, dynamic>.from(raw as Map);
      validateGrantReward(
        Map<String, dynamic>.from(achievement['reward'] as Map),
        'achievement.${achievement['id']}.reward',
        cardIds: cardIds,
      );
    }
  });

  test('gifts.json rewards válidos', () async {
    final json = await loadClashAssetJson('assets/data/clash/gifts.json');
    final gifts = json['gifts'] as List;
    assertUniqueIds(
      gifts.map((g) => (g as Map)['id'].toString()),
      'gifts.json',
    );
    for (final raw in gifts) {
      final gift = Map<String, dynamic>.from(raw as Map);
      validateGrantReward(
        Map<String, dynamic>.from(gift['rewards'] as Map),
        'gift.${gift['id']}.rewards',
        cardIds: cardIds,
      );
    }
  });

  test('news.json ids únicos', () async {
    final json = await loadClashAssetJson('assets/data/clash/news.json');
    final news = json['news'] as List;
    assertUniqueIds(news.map((n) => (n as Map)['id'].toString()), 'news.json');
  });

  test('character_events.json referencias cruzadas', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/character_events.json',
    );
    final events = json['events'] as List;
    assertUniqueIds(
      events.map((e) => (e as Map)['id'].toString()),
      'character_events.json',
    );
    final stageIds = <String>{};
    for (final raw in events) {
      final event = Map<String, dynamic>.from(raw as Map);
      final eventId = event['id'] as String;
      final featured = event['featuredCardId']?.toString();
      if (featured != null && featured.isNotEmpty) {
        expect(
          cardIds.contains(featured),
          isTrue,
          reason: '$eventId.featuredCardId inexistente: $featured',
        );
      }
      final stages = event['stages'] as List? ?? const [];
      expect(stages, isA<List>(), reason: '$eventId.stages invalido');
      if (stages.isEmpty) continue;
      for (final stageRaw in stages) {
        final stage = Map<String, dynamic>.from(stageRaw as Map);
        final stageId = stage['id'] as String;
        expect(
          stageIds.add(stageId),
          isTrue,
          reason: 'stage id duplicado: $stageId',
        );
        final context = '$eventId.$stageId';
        if (stage['type'] == 'match') {
          final rivalId = stage['rivalTeamId']?.toString() ?? '';
          expect(
            rivalTeamIds.contains(rivalId),
            isTrue,
            reason: '$context.rivalTeamId inexistente: $rivalId',
          );
        }
        validateGrantReward(
          Map<String, dynamic>.from(stage['firstClearRewards'] as Map? ?? {}),
          '$context.firstClearRewards',
          cardIds: cardIds,
        );
        validateGrantReward(
          Map<String, dynamic>.from(stage['repeatRewards'] as Map? ?? {}),
          '$context.repeatRewards',
          cardIds: cardIds,
        );
      }
    }
  });

  test('help_topics.json rutas conocidas', () async {
    final json = await loadClashAssetJson('assets/data/clash/help_topics.json');
    final topics = json['topics'] as List;
    assertUniqueIds(
      topics.map((t) => (t as Map)['id'].toString()),
      'help_topics.json',
    );
    for (final raw in topics) {
      final topic = Map<String, dynamic>.from(raw as Map);
      final routes = topic['relatedRoutes'] as List? ?? const [];
      for (final routeRaw in routes) {
        final route = Map<String, dynamic>.from(routeRaw as Map);
        final path = route['path']?.toString() ?? '';
        expect(
          clashHelpKnownRoutes.contains(path),
          isTrue,
          reason: 'help.${topic['id']} ruta desconocida: $path',
        );
      }
    }
  });

  test('catálogos de materiales coinciden con contrato de rewards', () {
    expect(expMaterialIds, ClashRewardIds.expMaterials);
    expect(techniqueBookIds, ClashRewardIds.techniqueBooks);
    expect(evolutionMaterialIds, ClashRewardIds.evolutionMaterials);
    expect(ticketIds, ClashRewardIds.tickets);
  });

  test('character_events.json puede estar vacio (modo Cadena XI)', () async {
    final json = await loadClashAssetJson(
      'assets/data/clash/character_events.json',
    );
    final events = json['events'] as List;
    expect(events, isA<List>());
  });
}
