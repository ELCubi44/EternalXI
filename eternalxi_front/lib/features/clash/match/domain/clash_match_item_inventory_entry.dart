import 'package:eternal_xi/features/clash/match/domain/clash_match_item.dart';

/// Entrada del inventario de partido: objeto + cantidad restante.
class ClashMatchItemInventoryEntry {
  const ClashMatchItemInventoryEntry({
    required this.item,
    required this.quantity,
  }) : assert(quantity >= 0, 'quantity no puede ser negativa');

  final ClashMatchItem item;
  final int quantity;

  bool get isAvailable => quantity > 0;

  ClashMatchItemInventoryEntry copyWith({int? quantity}) {
    return ClashMatchItemInventoryEntry(
      item: item,
      quantity: quantity ?? this.quantity,
    );
  }
}
