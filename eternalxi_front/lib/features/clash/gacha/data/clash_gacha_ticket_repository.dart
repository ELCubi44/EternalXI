import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_inventory_storage.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_tickets_local_datasource.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';

/// Catálogo + inventario local de tickets (Fase 26).
class ClashGachaTicketRepository {
  ClashGachaTicketRepository({
    required ClashGachaTicketsLocalDataSource dataSource,
    required ClashGachaTicketInventoryStorageBackend inventoryStorage,
  }) : _dataSource = dataSource,
       _inventoryStorage = inventoryStorage;

  final ClashGachaTicketsLocalDataSource _dataSource;
  final ClashGachaTicketInventoryStorageBackend _inventoryStorage;

  List<ClashGachaTicket>? _catalogCache;
  Map<String, int>? _quantitiesCache;

  Future<List<ClashGachaTicket>> fetchTickets() async {
    _catalogCache ??= await _dataSource.loadTickets();
    return _catalogCache!;
  }

  Future<ClashGachaTicket?> findTicket(String ticketId) async {
    final tickets = await fetchTickets();
    for (final ticket in tickets) {
      if (ticket.id == ticketId) {
        return ticket;
      }
    }
    return null;
  }

  Map<String, int> _loadQuantities() {
    return _quantitiesCache ??= _inventoryStorage.readQuantities();
  }

  int quantityFor(String ticketId) {
    return _loadQuantities()[ticketId] ?? 0;
  }

  Future<List<ClashGachaTicketInventoryEntry>> fetchInventoryEntries() async {
    final tickets = await fetchTickets();
    final quantities = _loadQuantities();
    final entries = <ClashGachaTicketInventoryEntry>[];
    for (final ticket in tickets) {
      final quantity = quantities[ticket.id] ?? 0;
      if (quantity > 0) {
        entries.add(
          ClashGachaTicketInventoryEntry(ticket: ticket, quantity: quantity),
        );
      }
    }
    return List<ClashGachaTicketInventoryEntry>.unmodifiable(entries);
  }

  Future<List<ClashGachaTicketInventoryEntry>> compatibleTicketsForBanner(
    String bannerId,
  ) async {
    final tickets = await fetchTickets();
    final quantities = _loadQuantities();
    return tickets
        .where((ticket) => ticket.isCompatibleWith(bannerId))
        .map(
          (ticket) => ClashGachaTicketInventoryEntry(
            ticket: ticket,
            quantity: quantities[ticket.id] ?? 0,
          ),
        )
        .toList(growable: false);
  }

  Future<bool> consume(String ticketId, {int amount = 1}) async {
    if (amount <= 0) {
      return true;
    }
    final quantities = Map<String, int>.from(_loadQuantities());
    final current = quantities[ticketId] ?? 0;
    if (current < amount) {
      return false;
    }
    final next = current - amount;
    if (next <= 0) {
      quantities.remove(ticketId);
    } else {
      quantities[ticketId] = next;
    }
    await _persist(quantities);
    return true;
  }

  Future<void> grant(String ticketId, int amount) async {
    if (amount <= 0) {
      return;
    }
    final quantities = Map<String, int>.from(_loadQuantities());
    quantities[ticketId] = (quantities[ticketId] ?? 0) + amount;
    await _persist(quantities);
  }

  Future<void> grantTickets(Map<String, int> grants) async {
    if (grants.isEmpty) {
      return;
    }
    final quantities = Map<String, int>.from(_loadQuantities());
    grants.forEach((ticketId, amount) {
      if (amount > 0) {
        quantities[ticketId] = (quantities[ticketId] ?? 0) + amount;
      }
    });
    await _persist(quantities);
  }

  Future<void> _persist(Map<String, int> quantities) async {
    _quantitiesCache = Map<String, int>.from(quantities);
    await _inventoryStorage.writeQuantities(quantities);
  }

  void clearCacheForTests() {
    _catalogCache = null;
    _quantitiesCache = null;
  }
}
