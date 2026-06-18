import 'package:eternal_xi/features/clash/cards/domain/clash_exp_material.dart';

/// Entrada del inventario local de materiales EXP.
class ClashExpMaterialInventoryEntry {
  const ClashExpMaterialInventoryEntry({
    required this.material,
    required this.quantity,
  });

  final ClashExpMaterial material;
  final int quantity;

  bool get isAvailable => quantity > 0;
}
