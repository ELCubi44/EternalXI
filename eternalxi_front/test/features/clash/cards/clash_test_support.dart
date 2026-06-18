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
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_repository.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_engine.dart';
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_local_datasource.dart';
import 'package:eternal_xi/features/clash/story/data/datasources/clash_story_progress_storage.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
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
  ClashGachaEngine? engine,
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
  return ClashGachaRepository(
    dataSource: TestGachaDataSource(),
    dailyStorage: dailyStorage ?? InMemoryClashGachaDailyBackend(),
    historyStorage: historyStorage ?? InMemoryClashGachaHistoryBackend(),
    pityStorage: pityStorage ?? InMemoryClashGachaPityBackend(),
    storyRepository: story,
    collectionRepository: collection,
    cardsRepository: cardsRepo,
    engine: engine,
    now: now,
  );
}

ClashInventoryRepository createTestInventoryRepository({
  ClashExpMaterialsRepository? expMaterialsRepository,
  ClashTechniqueBooksRepository? techniqueBooksRepository,
  ClashEvolutionMaterialsRepository? evolutionMaterialsRepository,
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
    matchItemsDataSource: matchItemsDataSource ?? TestMatchItemsDataSource(),
  );
}

ClashPlayerCollectionRepository createTestCollectionRepository({
  required ClashCardsRepository cardsRepository,
  ClashPlayerCollectionStorageBackend? storage,
  ClashExpMaterialsRepository? expMaterialsRepository,
  ClashTechniqueBooksRepository? techniqueBooksRepository,
  ClashEvolutionMaterialsRepository? evolutionMaterialsRepository,
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
  );
}
