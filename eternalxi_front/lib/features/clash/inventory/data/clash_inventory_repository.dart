import 'package:eternal_xi/features/clash/cards/data/repositories/clash_evolution_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_exp_materials_repository.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_technique_books_repository.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';
import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_item.dart';
import 'package:eternal_xi/features/clash/match/data/datasources/clash_match_items_local_datasource.dart';

/// Agrega inventarios locales existentes sin duplicar almacenamiento (Fase 22).
class ClashInventoryRepository {
  ClashInventoryRepository({
    required ClashExpMaterialsRepository expMaterialsRepository,
    required ClashTechniqueBooksRepository techniqueBooksRepository,
    required ClashEvolutionMaterialsRepository evolutionMaterialsRepository,
    ClashMatchItemsLocalDataSource? matchItemsDataSource,
  }) : _expMaterialsRepository = expMaterialsRepository,
       _techniqueBooksRepository = techniqueBooksRepository,
       _evolutionMaterialsRepository = evolutionMaterialsRepository,
       _matchItemsDataSource =
           matchItemsDataSource ?? ClashMatchItemsLocalDataSource();

  final ClashExpMaterialsRepository _expMaterialsRepository;
  final ClashTechniqueBooksRepository _techniqueBooksRepository;
  final ClashEvolutionMaterialsRepository _evolutionMaterialsRepository;
  final ClashMatchItemsLocalDataSource _matchItemsDataSource;

  Future<List<ClashInventoryItem>> fetchAllItems() async {
    final expEntries = await _expMaterialsRepository.fetchInventoryEntries();
    final bookEntries = await _techniqueBooksRepository.fetchInventoryEntries();
    final evolutionEntries = await _evolutionMaterialsRepository
        .fetchInventoryEntries();
    final matchKit = await _matchItemsDataSource.loadDefaultKit();

    final items = <ClashInventoryItem>[
      for (final entry in expEntries)
        ClashInventoryItem(
          id: entry.material.id,
          name: entry.material.name,
          description: entry.material.description,
          quantity: entry.quantity,
          category: ClashInventoryCategory.exp,
          usageHint: ClashInventoryUsageHint.fromCardDetail,
        ),
      for (final entry in bookEntries)
        ClashInventoryItem(
          id: entry.book.id,
          name: entry.book.name,
          description: entry.book.description,
          quantity: entry.quantity,
          category: ClashInventoryCategory.technique,
          usageHint: ClashInventoryUsageHint.fromCardDetail,
        ),
      for (final entry in evolutionEntries)
        ClashInventoryItem(
          id: entry.material.id,
          name: entry.material.name,
          description: entry.material.description,
          quantity: entry.quantity,
          category: ClashInventoryCategory.evolution,
          usageHint: ClashInventoryUsageHint.fromCardDetail,
        ),
      for (final entry in matchKit)
        ClashInventoryItem(
          id: entry.item.id,
          name: entry.item.name,
          description: entry.item.description,
          quantity: entry.quantity,
          category: ClashInventoryCategory.match,
          usageHint: ClashInventoryUsageHint.duringHalftime,
          isProvisionalMatchKit: true,
        ),
    ];

    return List<ClashInventoryItem>.unmodifiable(items);
  }

  Future<ClashInventorySummary> fetchSummary() async {
    final items = await fetchAllItems();
    return buildSummary(items);
  }

  static ClashInventorySummary buildSummary(List<ClashInventoryItem> items) {
    final byCategory = <ClashInventoryCategory, int>{
      for (final category in ClashInventoryCategory.values) category: 0,
    };
    var total = 0;
    for (final item in items) {
      byCategory[item.category] =
          (byCategory[item.category] ?? 0) + item.quantity;
      total += item.quantity;
    }
    return ClashInventorySummary(
      totalQuantity: total,
      quantityByCategory: Map<ClashInventoryCategory, int>.unmodifiable(
        byCategory,
      ),
    );
  }

  static List<ClashInventoryItem> filterItems(
    List<ClashInventoryItem> items,
    ClashInventoryFilter filter,
  ) {
    final category = filter.category;
    if (category == null) {
      return items;
    }
    return items
        .where((item) => item.category == category)
        .toList(growable: false);
  }

  static Map<ClashInventoryCategory, List<ClashInventoryItem>> groupByCategory(
    List<ClashInventoryItem> items,
  ) {
    return {
      for (final category in ClashInventoryCategory.values)
        category: items
            .where((item) => item.category == category)
            .toList(growable: false),
    };
  }
}
