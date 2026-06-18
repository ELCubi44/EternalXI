import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book.dart';

/// Entrada del inventario local de libros de técnica.
class ClashTechniqueBookInventoryEntry {
  const ClashTechniqueBookInventoryEntry({
    required this.book,
    required this.quantity,
  });

  final ClashTechniqueBook book;
  final int quantity;

  bool get isAvailable => quantity > 0;
}
