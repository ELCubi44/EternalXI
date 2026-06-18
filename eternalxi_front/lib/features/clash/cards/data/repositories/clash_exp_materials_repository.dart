import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_material_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_exp_materials_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material_inventory_entry.dart';

/// Catálogo e inventario local de materiales EXP (Fase 18).
class ClashExpMaterialsRepository {
  ClashExpMaterialsRepository({
    required ClashExpMaterialsLocalDataSource dataSource,
    required ClashExpMaterialInventoryStorageBackend inventoryStorage,
  }) : _dataSource = dataSource,
       _inventoryStorage = inventoryStorage;

  final ClashExpMaterialsLocalDataSource _dataSource;
  final ClashExpMaterialInventoryStorageBackend _inventoryStorage;

  List<ClashExpMaterial>? _catalogCache;
  ClashExpMaterialInventorySnapshot? _inventoryCache;

  static const defaultInventory = <String, int>{
    'basic-training-manual': 5,
    'advanced-training-manual': 2,
    'master-training-manual': 1,
  };

  Future<List<ClashExpMaterial>> fetchAllMaterials() async {
    _catalogCache ??= await _dataSource.loadMaterials();
    return List<ClashExpMaterial>.unmodifiable(_catalogCache!);
  }

  Future<ClashExpMaterial?> findById(String materialId) async {
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

  Future<List<ClashExpMaterialInventoryEntry>> fetchInventoryEntries() async {
    final catalog = await fetchAllMaterials();
    final quantities = loadInventoryQuantities();
    return catalog
        .map(
          (material) => ClashExpMaterialInventoryEntry(
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

  /// Consume materiales si hay cantidad suficiente. Devuelve false si no puede.
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

  ClashExpMaterialInventorySnapshot _loadInventorySnapshot() {
    _inventoryCache ??= _inventoryStorage.readSnapshot();
    return _inventoryCache!;
  }

  Future<void> _saveInventory(Map<String, int> quantities) async {
    final snapshot = ClashExpMaterialInventorySnapshot(quantities: quantities);
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
