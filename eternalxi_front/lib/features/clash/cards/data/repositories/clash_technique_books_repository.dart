import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_book_inventory_storage.dart';
import 'package:eternal_xi/features/clash/cards/data/datasources/clash_technique_books_local_datasource.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';

/// Catálogo e inventario local de libros de técnica (Fase 19).
class ClashTechniqueBooksRepository {
  ClashTechniqueBooksRepository({
    required ClashTechniqueBooksLocalDataSource dataSource,
    required ClashTechniqueBookInventoryStorageBackend inventoryStorage,
  }) : _dataSource = dataSource,
       _inventoryStorage = inventoryStorage;

  final ClashTechniqueBooksLocalDataSource _dataSource;
  final ClashTechniqueBookInventoryStorageBackend _inventoryStorage;

  List<ClashTechniqueBook>? _catalogCache;
  ClashTechniqueBookInventorySnapshot? _inventoryCache;

  static const defaultInventory = <String, int>{
    'basic-technique-book': 3,
    'advanced-technique-book': 1,
    'master-technique-book': 0,
  };

  Future<List<ClashTechniqueBook>> fetchAllBooks() async {
    _catalogCache ??= await _dataSource.loadBooks();
    return List<ClashTechniqueBook>.unmodifiable(_catalogCache!);
  }

  Future<ClashTechniqueBook?> findById(String bookId) async {
    final catalog = await fetchAllBooks();
    for (final book in catalog) {
      if (book.id == bookId) {
        return book;
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

  int quantityFor(String bookId) {
    return loadInventoryQuantities()[bookId] ?? 0;
  }

  Future<List<ClashTechniqueBookInventoryEntry>> fetchInventoryEntries() async {
    final catalog = await fetchAllBooks();
    final quantities = loadInventoryQuantities();
    return catalog
        .map(
          (book) => ClashTechniqueBookInventoryEntry(
            book: book,
            quantity: quantities[book.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<void> grantBooks(Map<String, int> additions) async {
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

  Future<bool> consumeBook({
    required String bookId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      return false;
    }

    final quantities = loadInventoryQuantities();
    final available = quantities[bookId] ?? 0;
    if (available < quantity) {
      return false;
    }

    final remaining = available - quantity;
    if (remaining <= 0) {
      quantities.remove(bookId);
    } else {
      quantities[bookId] = remaining;
    }

    await _saveInventory(quantities);
    return true;
  }

  ClashTechniqueBookInventorySnapshot _loadInventorySnapshot() {
    _inventoryCache ??= _inventoryStorage.readSnapshot();
    return _inventoryCache!;
  }

  Future<void> _saveInventory(Map<String, int> quantities) async {
    final snapshot = ClashTechniqueBookInventorySnapshot(
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
