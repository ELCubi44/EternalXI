import 'package:eternal_xi/features/clash/cards/data/datasources/clash_cards_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_books_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_daily_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_history_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_pity_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_tickets_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_grant_service.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_local_datasource.dart';
import 'package:eternal_xi/features/clash/shop/data/clash_shop_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievement_event_sink.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_local_datasource.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_repository.dart';
import 'package:eternal_xi/features/clash/achievements/data/clash_achievements_storage.dart';
import 'package:eternal_xi/features/clash/achievements/domain/clash_achievement.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_mission_progress_event_hub.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_weekly_missions_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_local_datasource.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_repository.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_weekly_mission.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_mission_event_sink.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_local_datasource.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_repository.dart';
import 'package:eternal_xi/features/clash/missions/data/clash_daily_missions_storage.dart';
import 'package:eternal_xi/features/clash/missions/domain/clash_daily_mission.dart';
import 'package:eternal_xi/features/clash/match/data/datasources/clash_match_items_local_datasource.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_item_inventory_entry.dart';

const clashTestExpMaterialsJson = '''
{
  "materials": [
    {
      "id": "basic-training-manual",
      "name": "Manual básico de entrenamiento",
      "description": "Manual introductorio.",
      "xpAmount": 50
    },
    {
      "id": "advanced-training-manual",
      "name": "Manual avanzado de entrenamiento",
      "description": "Manual intermedio.",
      "xpAmount": 200
    },
    {
      "id": "master-training-manual",
      "name": "Manual maestro de entrenamiento",
      "description": "Manual experto.",
      "xpAmount": 800
    }
  ]
}
''';

const clashTestTechniqueBooksJson = '''
{
  "books": [
    {
      "id": "basic-technique-book",
      "name": "Libro técnico básico",
      "description": "Sube una supertécnica un paso.",
      "levelUpSteps": 1
    },
    {
      "id": "advanced-technique-book",
      "name": "Libro técnico avanzado",
      "description": "Sube una supertécnica dos pasos.",
      "levelUpSteps": 2
    },
    {
      "id": "master-technique-book",
      "name": "Libro técnico maestro",
      "description": "Sube una supertécnica cuatro pasos.",
      "levelUpSteps": 4
    }
  ]
}
''';

const clashTestEvolutionMaterialsJson = '''
{
  "materials": [
    {
      "id": "insignia-r",
      "name": "Insignia R",
      "description": "Material para evolucionar N a R.",
      "targetRarity": "r"
    },
    {
      "id": "insignia-sr",
      "name": "Insignia SR",
      "description": "Material para evolucionar R a SR.",
      "targetRarity": "sr"
    }
  ]
}
''';

const clashTestMatchItemsJson = '''
{
  "items": [
    {
      "id": "test-item-pt",
      "name": "Bebida técnica test",
      "description": "Recupera PT de un jugador.",
      "type": "recoverPtSingle",
      "amount": 20,
      "targetCount": 1,
      "category": "pt"
    },
    {
      "id": "test-item-stamina",
      "name": "Venda test",
      "description": "Recupera resistencia.",
      "type": "recoverStaminaSingle",
      "amount": 15,
      "targetCount": 1,
      "category": "stamina"
    }
  ],
  "defaultKit": {
    "test-item-pt": 2,
    "test-item-stamina": 1
  }
}
''';

const clashTestGachaCardsJson = '''
{
  "cards": [
    {
      "id": "gacha-card-a",
      "playerId": 101,
      "name": "Gacha A",
      "team": "Test FC",
      "rarity": "n",
      "level": 1,
      "style": "valiente",
      "position": "striker",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 10, "pass": 10, "dribble": 10, "shot": 30, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st-a", "name": "Tiro", "description": "T", "type": "shot", "style": "valiente", "basePower": 35, "ptCost": 10, "level": "normal"}]
    },
    {
      "id": "gacha-card-b",
      "playerId": 102,
      "name": "Gacha B",
      "team": "Test FC",
      "rarity": "n",
      "level": 1,
      "style": "agil",
      "position": "attackingMidfielder",
      "basicPortraitPath": "placeholder",
      "stats": {"save": 2, "defense": 12, "pass": 20, "dribble": 15, "shot": 12, "techniquePoints": 10, "stamina": 100},
      "superTechniques": [{"id": "st-b", "name": "Pase", "description": "T", "type": "dribble", "style": "agil", "basePower": 30, "ptCost": 10, "level": "normal"}]
    }
  ]
}
''';

const clashTestGachaBannersJson = '''
{
  "rates": { "n": 60, "r": 30, "sr": 10, "lr": 0, "xi": 0 },
  "banners": [
    {
      "id": "starter-banner-001",
      "name": "Invocación inicial",
      "description": "Banner de prueba",
      "singleCost": 10,
      "multiCost": 95,
      "multiCount": 10,
      "dailyDiscountCost": 1,
      "dailyDiscountAvailable": true,
      "poolCardIds": ["gacha-card-a", "gacha-card-b"]
    }
  ]
}
''';

const clashTestGachaTicketsJson = '''
{
  "tickets": [
    {
      "id": "starter-single-ticket",
      "name": "Ticket de invocación inicial",
      "description": "Permite una invocación single en el banner inicial",
      "compatibleBannerIds": ["starter-banner-001"],
      "pullCount": 1,
      "rarityGuarantee": null,
      "iconKey": null
    },
    {
      "id": "other-banner-ticket",
      "name": "Ticket otro banner",
      "description": "Solo para otro banner",
      "compatibleBannerIds": ["other-banner-999"],
      "pullCount": 1,
      "rarityGuarantee": null,
      "iconKey": null
    }
  ]
}
''';

class TestMatchItemsDataSource extends ClashMatchItemsLocalDataSource {
  @override
  Future<List<ClashMatchItemInventoryEntry>> loadDefaultKit() async {
    return parseDefaultKitJson(clashTestMatchItemsJson);
  }
}

class GachaTestCardsDataSource extends ClashCardsLocalDataSource {
  @override
  Future<List<ClashCardCatalogEntry>> loadCards() async {
    return parseCardsJson(clashTestGachaCardsJson);
  }
}

class TestGachaDataSource extends ClashGachaLocalDataSource {
  @override
  Future<ClashGachaCatalog> loadCatalog() async {
    return parseCatalogJson(clashTestGachaBannersJson);
  }
}

class TestGachaTicketsDataSource extends ClashGachaTicketsLocalDataSource {
  @override
  Future<List<ClashGachaTicket>> loadTickets() async {
    return parseTicketsJson(clashTestGachaTicketsJson);
  }
}

ClashGachaTicketRepository createTestTicketRepository({
  ClashGachaTicketInventoryStorageBackend? inventoryStorage,
}) {
  return ClashGachaTicketRepository(
    dataSource: TestGachaTicketsDataSource(),
    inventoryStorage:
        inventoryStorage ?? InMemoryClashGachaTicketInventoryBackend(),
  );
}

class TestExpMaterialsDataSource extends ClashExpMaterialsLocalDataSource {
  @override
  Future<List<ClashExpMaterial>> loadMaterials() async {
    return parseMaterialsJson(clashTestExpMaterialsJson);
  }
}

class TestTechniqueBooksDataSource extends ClashTechniqueBooksLocalDataSource {
  @override
  Future<List<ClashTechniqueBook>> loadBooks() async {
    return parseBooksJson(clashTestTechniqueBooksJson);
  }
}

class TestEvolutionMaterialsDataSource
    extends ClashEvolutionMaterialsLocalDataSource {
  @override
  Future<List<ClashEvolutionMaterial>> loadMaterials() async {
    return parseMaterialsJson(clashTestEvolutionMaterialsJson);
  }
}

ClashExpMaterialsRepository createTestExpMaterialsRepository({
  ClashExpMaterialInventoryStorageBackend? inventoryStorage,
}) {
  return ClashExpMaterialsRepository(
    dataSource: TestExpMaterialsDataSource(),
    inventoryStorage:
        inventoryStorage ?? InMemoryClashExpMaterialInventoryBackend(),
  );
}

ClashTechniqueBooksRepository createTestTechniqueBooksRepository({
  ClashTechniqueBookInventoryStorageBackend? inventoryStorage,
}) {
  return ClashTechniqueBooksRepository(
    dataSource: TestTechniqueBooksDataSource(),
    inventoryStorage:
        inventoryStorage ?? InMemoryClashTechniqueBookInventoryBackend(),
  );
}

ClashEvolutionMaterialsRepository createTestEvolutionMaterialsRepository({
  ClashEvolutionMaterialInventoryStorageBackend? inventoryStorage,
}) {
  return ClashEvolutionMaterialsRepository(
    dataSource: TestEvolutionMaterialsDataSource(),
    inventoryStorage:
        inventoryStorage ?? InMemoryClashEvolutionMaterialInventoryBackend(),
  );
}

Future<ClashGachaRepository> createTestGachaRepository({
  ClashCardsRepository? cardsRepository,
  ClashPlayerCollectionRepository? collectionRepository,
  ClashStoryRepository? storyRepository,
  ClashGachaDailyStorageBackend? dailyStorage,
  ClashGachaHistoryStorageBackend? historyStorage,
  ClashGachaPityStorageBackend? pityStorage,
  ClashGachaTicketRepository? ticketRepository,
  ClashGachaEngine? engine,
  ClashDailyMissionEventSink? missionEventSink,
  ClashAchievementEventSink? achievementEventSink,
  ClashMissionProgressEventHub? progressEventHub,
  DateTime Function()? now,
  int initialGems = 200,
}) async {
  final cardsRepo =
      cardsRepository ?? ClashCardsRepository(GachaTestCardsDataSource());
  final collection =
      collectionRepository ??
      createTestCollectionRepository(cardsRepository: cardsRepo);
  final storyProgress = InMemoryClashStoryProgressBackend();
  if (storyRepository == null) {
    await storyProgress.writeProgress(
      ClashStoryProgress(walletGems: initialGems),
    );
  }
  final story =
      storyRepository ??
      ClashStoryRepository(
        dataSource: ClashStoryLocalDataSource(),
        progressStorage: storyProgress,
        collectionRepository: collection,
      );
  final tickets = ticketRepository ?? createTestTicketRepository();
  return ClashGachaRepository(
    dataSource: TestGachaDataSource(),
    dailyStorage: dailyStorage ?? InMemoryClashGachaDailyBackend(),
    historyStorage: historyStorage ?? InMemoryClashGachaHistoryBackend(),
    pityStorage: pityStorage ?? InMemoryClashGachaPityBackend(),
    ticketRepository: tickets,
    storyRepository: story,
    collectionRepository: collection,
    cardsRepository: cardsRepo,
    engine: engine,
    missionEventSink: missionEventSink,
    achievementEventSink: achievementEventSink,
    progressEventHub: progressEventHub,
    now: now,
  );
}

ClashInventoryRepository createTestInventoryRepository({
  ClashExpMaterialsRepository? expMaterialsRepository,
  ClashTechniqueBooksRepository? techniqueBooksRepository,
  ClashEvolutionMaterialsRepository? evolutionMaterialsRepository,
  ClashGachaTicketRepository? ticketRepository,
  ClashMatchItemsLocalDataSource? matchItemsDataSource,
}) {
  return ClashInventoryRepository(
    expMaterialsRepository:
        expMaterialsRepository ?? createTestExpMaterialsRepository(),
    techniqueBooksRepository:
        techniqueBooksRepository ?? createTestTechniqueBooksRepository(),
    evolutionMaterialsRepository:
        evolutionMaterialsRepository ??
        createTestEvolutionMaterialsRepository(),
    ticketRepository: ticketRepository ?? createTestTicketRepository(),
    matchItemsDataSource: matchItemsDataSource ?? TestMatchItemsDataSource(),
  );
}

ClashPlayerCollectionRepository createTestCollectionRepository({
  required ClashCardsRepository cardsRepository,
  ClashPlayerCollectionStorageBackend? storage,
  ClashExpMaterialsRepository? expMaterialsRepository,
  ClashTechniqueBooksRepository? techniqueBooksRepository,
  ClashEvolutionMaterialsRepository? evolutionMaterialsRepository,
  ClashDailyMissionEventSink? missionEventSink,
  ClashAchievementEventSink? achievementEventSink,
  ClashMissionProgressEventHub? progressEventHub,
}) {
  return ClashPlayerCollectionRepository(
    storage: storage ?? InMemoryClashPlayerCollectionBackend(),
    cardsRepository: cardsRepository,
    expMaterialsRepository:
        expMaterialsRepository ?? createTestExpMaterialsRepository(),
    techniqueBooksRepository:
        techniqueBooksRepository ?? createTestTechniqueBooksRepository(),
    evolutionMaterialsRepository:
        evolutionMaterialsRepository ??
        createTestEvolutionMaterialsRepository(),
    missionEventSink: missionEventSink,
    achievementEventSink: achievementEventSink,
    progressEventHub: progressEventHub,
  );
}

const clashTestShopProductsJson = '''
{
  "products": [
    {
      "id": "shop-basic-training-pack",
      "name": "Pack entrenamiento básico",
      "description": "Dos manuales básicos.",
      "costCoins": 300,
      "grants": [
        {
          "type": "expMaterial",
          "id": "basic-training-manual",
          "quantity": 2,
          "label": "Manual básico de entrenamiento"
        }
      ]
    },
    {
      "id": "shop-basic-technique-book",
      "name": "Libro técnico básico",
      "description": "Un libro técnico.",
      "costCoins": 500,
      "grants": [
        {
          "type": "techniqueBook",
          "id": "basic-technique-book",
          "quantity": 1,
          "label": "Libro técnico básico"
        }
      ]
    },
    {
      "id": "shop-insignia-r",
      "name": "Insignia R",
      "description": "Insignia de evolución.",
      "costCoins": 800,
      "grants": [
        {
          "type": "evolutionMaterial",
          "id": "insignia-r",
          "quantity": 1,
          "label": "Insignia R"
        }
      ]
    },
    {
      "id": "shop-starter-ticket",
      "name": "Ticket de invocación inicial",
      "description": "Un ticket.",
      "costCoins": 1000,
      "grants": [
        {
          "type": "ticket",
          "id": "starter-single-ticket",
          "quantity": 1,
          "label": "Ticket de invocación inicial"
        }
      ]
    }
  ]
}
''';

class TestShopDataSource extends ClashShopLocalDataSource {
  @override
  Future<List<ClashShopProduct>> loadProducts() async {
    return parseProductsJson(clashTestShopProductsJson);
  }
}

Future<ClashShopRepository> createTestShopRepository({
  ClashStoryRepository? storyRepository,
  ClashPlayerCollectionRepository? collectionRepository,
  ClashGachaTicketRepository? ticketRepository,
  ClashShopGrantService? grantService,
  ClashDailyMissionEventSink? missionEventSink,
  ClashMissionProgressEventHub? progressEventHub,
  int initialCoins = 2000,
  int initialGems = 100,
}) async {
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection =
      collectionRepository ??
      createTestCollectionRepository(cardsRepository: cardsRepo);
  final storyProgress = InMemoryClashStoryProgressBackend();
  final story =
      storyRepository ??
      ClashStoryRepository(
        dataSource: ClashStoryLocalDataSource(),
        progressStorage: storyProgress,
        collectionRepository: collection,
        ticketRepository: ticketRepository ?? createTestTicketRepository(),
      );
  if (storyRepository == null) {
    await storyProgress.writeProgress(
      ClashStoryProgress(walletCoins: initialCoins, walletGems: initialGems),
    );
  }
  final tickets = ticketRepository ?? createTestTicketRepository();
  return ClashShopRepository(
    dataSource: TestShopDataSource(),
    storyRepository: story,
    grantService:
        grantService ??
        ClashShopGrantService(
          collectionRepository: collection,
          ticketRepository: tickets,
        ),
    missionEventSink: missionEventSink,
    progressEventHub: progressEventHub,
  );
}

const clashTestDailyMissionsJson = '''
{
  "missions": [
    {
      "id": "daily-play-match",
      "title": "Juega un partido",
      "description": "Completa cualquier partido de Clash.",
      "type": "playMatch",
      "target": 1,
      "reward": { "coins": 300 }
    },
    {
      "id": "daily-win-match",
      "title": "Gana un partido",
      "description": "Consigue la victoria en un partido.",
      "type": "winMatch",
      "target": 1,
      "reward": { "gems": 1 }
    },
    {
      "id": "daily-summon",
      "title": "Haz una invocación",
      "description": "Realiza una invocación en cualquier banner.",
      "type": "summon",
      "target": 1,
      "reward": { "coins": 500 }
    },
    {
      "id": "daily-shop-purchase",
      "title": "Compra en tienda",
      "description": "Compra un producto en la tienda local.",
      "type": "shopPurchase",
      "target": 1,
      "reward": {
        "expMaterial": {
          "id": "basic-training-manual",
          "quantity": 1
        }
      }
    },
    {
      "id": "daily-use-exp-material",
      "title": "Usa un material de EXP",
      "description": "Aplica un manual de entrenamiento a una carta.",
      "type": "useExpMaterial",
      "target": 1,
      "reward": { "coins": 200 }
    },
    {
      "id": "daily-upgrade-technique",
      "title": "Mejora una supertécnica",
      "description": "Usa un libro técnico en una supertécnica.",
      "type": "upgradeTechnique",
      "target": 1,
      "reward": {
        "techniqueBook": {
          "id": "basic-technique-book",
          "quantity": 1
        }
      }
    }
  ]
}
''';

class TestMissionsDataSource extends ClashDailyMissionsLocalDataSource {
  @override
  Future<List<ClashDailyMission>> loadMissions() async {
    return parseMissionsJson(clashTestDailyMissionsJson);
  }
}

Future<
  ({
    ClashDailyMissionsRepository missions,
    ClashDailyMissionEventSink sink,
    ClashStoryRepository story,
    ClashPlayerCollectionRepository collection,
  })
>
createTestMissionsSetup({
  ClashDailyMissionsStorageBackend? storage,
  DateTime Function()? now,
  int initialCoins = 0,
  int initialGems = 0,
}) async {
  final sink = ClashDailyMissionEventSink();
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    missionEventSink: sink,
  );
  final storyProgress = InMemoryClashStoryProgressBackend();
  await storyProgress.writeProgress(
    ClashStoryProgress(walletCoins: initialCoins, walletGems: initialGems),
  );
  final story = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: storyProgress,
    collectionRepository: collection,
    ticketRepository: createTestTicketRepository(),
  );
  final tickets = createTestTicketRepository();
  final missions = ClashDailyMissionsRepository(
    dataSource: TestMissionsDataSource(),
    storage: storage ?? InMemoryClashDailyMissionsBackend(),
    storyRepository: story,
    grantService: ClashShopGrantService(
      collectionRepository: collection,
      ticketRepository: tickets,
    ),
    now: now,
  );
  sink.bind(missions);
  return (missions: missions, sink: sink, story: story, collection: collection);
}

const clashTestAchievementsJson = '''
{
  "achievements": [
    {
      "id": "achievement-first-match",
      "title": "Primer partido",
      "description": "Completa tu primer partido de Clash.",
      "type": "playMatch",
      "target": 1,
      "reward": { "coins": 500 }
    },
    {
      "id": "achievement-first-win",
      "title": "Primera victoria",
      "description": "Consigue tu primera victoria en un partido.",
      "type": "winMatch",
      "target": 1,
      "reward": { "gems": 2 }
    },
    {
      "id": "achievement-summon-novice",
      "title": "Invocador novato",
      "description": "Obtén cartas en 5 invocaciones.",
      "type": "summon",
      "target": 5,
      "reward": {
        "ticket": {
          "id": "starter-single-ticket",
          "quantity": 1
        }
      }
    },
    {
      "id": "achievement-collector-starter",
      "title": "Coleccionista inicial",
      "description": "Posee 10 cartas únicas en tu colección.",
      "type": "collectCards",
      "target": 10,
      "reward": { "gems": 2 }
    },
    {
      "id": "achievement-trainer-beginner",
      "title": "Entrenador principiante",
      "description": "Sube de nivel a 5 cartas distintas.",
      "type": "levelUpCard",
      "target": 5,
      "reward": {
        "expMaterial": {
          "id": "advanced-training-manual",
          "quantity": 1
        }
      }
    },
    {
      "id": "achievement-technique-upgraded",
      "title": "Técnica mejorada",
      "description": "Mejora supertécnicas 3 veces con libros.",
      "type": "upgradeTechnique",
      "target": 3,
      "reward": {
        "techniqueBook": {
          "id": "advanced-technique-book",
          "quantity": 1
        }
      }
    },
    {
      "id": "achievement-first-evolution",
      "title": "Primera evolución",
      "description": "Evoluciona una carta por primera vez.",
      "type": "evolveCard",
      "target": 1,
      "reward": {
        "evolutionMaterial": {
          "id": "insignia-r",
          "quantity": 1
        }
      }
    },
    {
      "id": "achievement-skill-tree-unlock",
      "title": "Árbol desbloqueado",
      "description": "Desbloquea tu primer nodo del árbol de habilidades.",
      "type": "unlockSkillNode",
      "target": 1,
      "reward": { "coins": 1000 }
    }
  ]
}
''';

class TestAchievementsDataSource extends ClashAchievementsLocalDataSource {
  @override
  Future<List<ClashAchievement>> loadAchievements() async {
    return parseAchievementsJson(clashTestAchievementsJson);
  }
}

Future<
  ({
    ClashAchievementsRepository achievements,
    ClashAchievementEventSink sink,
    ClashStoryRepository story,
    ClashPlayerCollectionRepository collection,
  })
>
createTestAchievementsSetup({
  ClashAchievementsStorageBackend? storage,
  DateTime Function()? now,
  int initialCoins = 0,
  int initialGems = 0,
}) async {
  final sink = ClashAchievementEventSink();
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    achievementEventSink: sink,
  );
  final storyProgress = InMemoryClashStoryProgressBackend();
  await storyProgress.writeProgress(
    ClashStoryProgress(walletCoins: initialCoins, walletGems: initialGems),
  );
  final story = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: storyProgress,
    collectionRepository: collection,
    ticketRepository: createTestTicketRepository(),
  );
  final tickets = createTestTicketRepository();
  final achievements = ClashAchievementsRepository(
    dataSource: TestAchievementsDataSource(),
    storage: storage ?? InMemoryClashAchievementsBackend(),
    storyRepository: story,
    grantService: ClashShopGrantService(
      collectionRepository: collection,
      ticketRepository: tickets,
    ),
    now: now,
  );
  sink.bind(achievements);
  return (
    achievements: achievements,
    sink: sink,
    story: story,
    collection: collection,
  );
}

const clashTestWeeklyMissionsJson = '''
{
  "missions": [
    {
      "id": "weekly-play-matches",
      "title": "Juega 5 partidos",
      "description": "Completa 5 partidos esta semana.",
      "type": "playMatch",
      "target": 5,
      "reward": { "coins": 2000 }
    },
    {
      "id": "weekly-win-matches",
      "title": "Gana 3 partidos",
      "description": "Consigue 3 victorias esta semana.",
      "type": "winMatch",
      "target": 3,
      "reward": { "gems": 5 }
    },
    {
      "id": "weekly-summon",
      "title": "Haz 10 invocaciones",
      "description": "Realiza 10 invocaciones.",
      "type": "summon",
      "target": 10,
      "reward": {
        "ticket": {
          "id": "starter-single-ticket",
          "quantity": 2
        }
      }
    },
    {
      "id": "weekly-shop-purchase",
      "title": "Compra 3 veces en tienda",
      "description": "Compra en tienda 3 veces.",
      "type": "shopPurchase",
      "target": 3,
      "reward": {
        "expMaterial": {
          "id": "advanced-training-manual",
          "quantity": 1
        }
      }
    },
    {
      "id": "weekly-level-up-cards",
      "title": "Sube 10 niveles de cartas",
      "description": "Sube de nivel cartas 10 veces.",
      "type": "levelUpCard",
      "target": 10,
      "reward": {
        "expMaterial": {
          "id": "advanced-training-manual",
          "quantity": 2
        }
      }
    },
    {
      "id": "weekly-upgrade-technique",
      "title": "Mejora 5 supertécnicas",
      "description": "Mejora supertécnicas 5 veces.",
      "type": "upgradeTechnique",
      "target": 5,
      "reward": {
        "techniqueBook": {
          "id": "advanced-technique-book",
          "quantity": 1
        }
      }
    },
    {
      "id": "weekly-evolve-cards",
      "title": "Evoluciona 2 cartas",
      "description": "Evoluciona cartas 2 veces.",
      "type": "evolveCard",
      "target": 2,
      "reward": {
        "evolutionMaterial": {
          "id": "insignia-sr",
          "quantity": 1
        }
      }
    },
    {
      "id": "weekly-unlock-skill-nodes",
      "title": "Desbloquea 3 nodos de árbol",
      "description": "Desbloquea nodos del árbol 3 veces.",
      "type": "unlockSkillNode",
      "target": 3,
      "reward": { "coins": 3000 }
    }
  ]
}
''';

class TestWeeklyMissionsDataSource extends ClashWeeklyMissionsLocalDataSource {
  @override
  Future<List<ClashWeeklyMission>> loadMissions() async {
    return parseMissionsJson(clashTestWeeklyMissionsJson);
  }
}

ClashMissionProgressEventHub createTestProgressEventHub({
  required ClashDailyMissionEventSink daily,
  ClashWeeklyMissionEventSink? weekly,
  ClashAchievementEventSink? achievements,
}) {
  return ClashMissionProgressEventHub(
    daily: daily,
    weekly: weekly ?? ClashWeeklyMissionEventSink(),
    achievements: achievements ?? ClashAchievementEventSink(),
  );
}

Future<
  ({
    ClashWeeklyMissionsRepository weekly,
    ClashWeeklyMissionEventSink weeklySink,
    ClashStoryRepository story,
    ClashPlayerCollectionRepository collection,
  })
>
createTestWeeklyMissionsSetup({
  ClashWeeklyMissionsStorageBackend? storage,
  DateTime Function()? now,
  int initialCoins = 0,
  int initialGems = 0,
}) async {
  final weeklySink = ClashWeeklyMissionEventSink();
  final cardsRepo = ClashCardsRepository(GachaTestCardsDataSource());
  final collection = createTestCollectionRepository(
    cardsRepository: cardsRepo,
    progressEventHub: createTestProgressEventHub(
      daily: ClashDailyMissionEventSink(),
      weekly: weeklySink,
    ),
  );
  final storyProgress = InMemoryClashStoryProgressBackend();
  await storyProgress.writeProgress(
    ClashStoryProgress(walletCoins: initialCoins, walletGems: initialGems),
  );
  final story = ClashStoryRepository(
    dataSource: ClashStoryLocalDataSource(),
    progressStorage: storyProgress,
    collectionRepository: collection,
    ticketRepository: createTestTicketRepository(),
  );
  final tickets = createTestTicketRepository();
  final weekly = ClashWeeklyMissionsRepository(
    dataSource: TestWeeklyMissionsDataSource(),
    storage: storage ?? InMemoryClashWeeklyMissionsBackend(),
    storyRepository: story,
    grantService: ClashShopGrantService(
      collectionRepository: collection,
      ticketRepository: tickets,
    ),
    now: now,
  );
  weeklySink.bind(weekly);
  return (
    weekly: weekly,
    weeklySink: weeklySink,
    story: story,
    collection: collection,
  );
}

const clashTestNewsJson = '''
{
  "news": [
    {
      "id": "news-pinned-old",
      "title": "Pinned antigua",
      "summary": "Resumen pinned antigua",
      "body": "Cuerpo pinned antigua",
      "type": "update",
      "publishedAt": "2026-06-01",
      "isPinned": true
    },
    {
      "id": "news-pinned-new",
      "title": "Pinned reciente",
      "summary": "Resumen pinned reciente",
      "body": "Cuerpo pinned reciente",
      "type": "update",
      "publishedAt": "2026-06-05",
      "isPinned": true
    },
    {
      "id": "news-latest",
      "title": "Última noticia",
      "summary": "Resumen última",
      "body": "Cuerpo última",
      "type": "event",
      "publishedAt": "2026-06-10",
      "isPinned": false
    },
    {
      "id": "news-banner",
      "title": "Banner local",
      "summary": "Resumen banner",
      "body": "Cuerpo banner",
      "type": "banner",
      "publishedAt": "2026-05-28",
      "isPinned": false
    },
    {
      "id": "news-maintenance",
      "title": "Aviso mantenimiento",
      "summary": "Resumen aviso",
      "body": "Cuerpo aviso",
      "type": "maintenance",
      "publishedAt": "2026-06-09",
      "isPinned": false
    },
    {
      "id": "news-gift",
      "title": "Regalo de prueba",
      "summary": "Resumen regalo",
      "body": "Cuerpo regalo",
      "type": "gift",
      "publishedAt": "2026-06-07",
      "isPinned": false
    }
  ]
}
''';

class TestNewsDataSource extends ClashNewsLocalDataSource {
  @override
  Future<List<ClashNewsItem>> loadNews() async {
    return parseNewsJson(clashTestNewsJson);
  }
}

Future<({ClashNewsRepository news, ClashNewsReadStorageBackend storage})>
createTestNewsSetup({
  ClashNewsReadStorageBackend? storage,
  ClashNewsLocalDataSource? dataSource,
}) async {
  final readStorage = storage ?? InMemoryClashNewsReadBackend();
  final news = ClashNewsRepository(
    dataSource: dataSource ?? TestNewsDataSource(),
    storage: readStorage,
  );
  return (news: news, storage: readStorage);
}
