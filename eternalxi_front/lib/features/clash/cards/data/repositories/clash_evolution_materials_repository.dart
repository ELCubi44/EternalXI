import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_evolution_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_evolution_material_inventory_entry.dart';

/// Catálogo e inventario local de materiales de evolución (Fase 20).
class ClashEvolutionMaterialsRepository {
  ClashEvolutionMaterialsRepository({
    required ClashEvolutionMaterialsLocalDataSource dataSource,
    required ClashEvolutionMaterialInventoryStorageBackend inventoryStorage,
  }) : _dataSource = dataSource,
       _inventoryStorage = inventoryStorage;

  final ClashEvolutionMaterialsLocalDataSource _dataSource;
  final ClashEvolutionMaterialInventoryStorageBackend _inventoryStorage;

  List<ClashEvolutionMaterial>? _catalogCache;
  ClashEvolutionMaterialInventorySnapshot? _inventoryCache;

  static const defaultInventory = <String, int>{
    'insignia-r': 3,
    'insignia-sr': 1,
  };

  Future<List<ClashEvolutionMaterial>> fetchAllMaterials() async {
    _catalogCache ??= await _dataSource.loadMaterials();
    return List<ClashEvolutionMaterial>.unmodifiable(_catalogCache!);
  }

  Future<ClashEvolutionMaterial?> findById(String materialId) async {
    final catalog = await fetchAllMaterials();
    for (final material in catalog) {
      if (material.id == materialId) {
        return material;
      }
    }
    return null;
  }

  Map<String, int> loadInventoryQuantities() {
    final snapshot = _loadInventorySnapshot();
    if (snapshot.quantities.isEmpty) {
      return Map<String, int>.from(defaultInventory);
    }
    return Map<String, int>.from(snapshot.quantities);
  }

  int quantityFor(String materialId) {
    return loadInventoryQuantities()[materialId] ?? 0;
  }

  Future<List<ClashEvolutionMaterialInventoryEntry>>
  fetchInventoryEntries() async {
    final catalog = await fetchAllMaterials();
    final quantities = loadInventoryQuantities();
    return catalog
        .map(
          (material) => ClashEvolutionMaterialInventoryEntry(
            material: material,
            quantity: quantities[material.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<void> grantMaterials(Map<String, int> additions) async {
    if (additions.isEmpty) {
      return;
    }

    final quantities = loadInventoryQuantities();
    var changed = false;
    for (final entry in additions.entries) {
      if (entry.value <= 0) {
        continue;
      }
      quantities[entry.key] = (quantities[entry.key] ?? 0) + entry.value;
      changed = true;
    }

    if (changed) {
      await _saveInventory(quantities);
    }
  }

  Future<bool> consumeMaterial({
    required String materialId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return false;
    }

    final quantities = loadInventoryQuantities();
    final available = quantities[materialId] ?? 0;
    if (available < quantity) {
      return false;
    }

    final remaining = available - quantity;
    if (remaining <= 0) {
      quantities.remove(materialId);
    } else {
      quantities[materialId] = remaining;
    }

    await _saveInventory(quantities);
    return true;
  }

  ClashEvolutionMaterialInventorySnapshot _loadInventorySnapshot() {
    _inventoryCache ??= _inventoryStorage.readSnapshot();
    return _inventoryCache!;
  }

  Future<void> _saveInventory(Map<String, int> quantities) async {
    final snapshot = ClashEvolutionMaterialInventorySnapshot(
      quantities: quantities,
    );
    _inventoryCache = snapshot;
    await _inventoryStorage.writeSnapshot(snapshot);
  }

  Future<void> seedDefaultInventoryIfEmpty() async {
    final snapshot = _loadInventorySnapshot();
    if (snapshot.quantities.isNotEmpty) {
      return;
    }
    await _saveInventory(Map<String, int>.from(defaultInventory));
  }

  void clearCacheForTests() {
    _catalogCache = null;
    _inventoryCache = null;
  }
}
