import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_player_collection_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material.dart';

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

class TestExpMaterialsDataSource extends ClashExpMaterialsLocalDataSource {
  @override
  Future<List<ClashExpMaterial>> loadMaterials() async {
    return parseMaterialsJson(clashTestExpMaterialsJson);
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

ClashPlayerCollectionRepository createTestCollectionRepository({
  required ClashCardsRepository cardsRepository,
  ClashPlayerCollectionStorageBackend? storage,
  ClashExpMaterialsRepository? expMaterialsRepository,
}) {
  return ClashPlayerCollectionRepository(
    storage: storage ?? InMemoryClashPlayerCollectionBackend(),
    cardsRepository: cardsRepository,
    expMaterialsRepository:
        expMaterialsRepository ?? createTestExpMaterialsRepository(),
  );
}
