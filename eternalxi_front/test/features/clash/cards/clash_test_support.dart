import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
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
import 'package:eternal_xi/features/clash/inventory/data/clash_inventory_repository.dart';
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

class TestMatchItemsDataSource extends ClashMatchItemsLocalDataSource {
  @override
  Future<List<ClashMatchItemInventoryEntry>> loadDefaultKit() async {
    return parseDefaultKitJson(clashTestMatchItemsJson);
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
