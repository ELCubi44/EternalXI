import 'package:eternal_xi/features/clash/inventory/domain/clash_inventory_category.dart';

enum ClashInventoryUsageHint { fromCardDetail, duringHalftime, useInSummon }

/// Ítem unificado para la pantalla de inventario Clash.
class ClashInventoryItem {
  const ClashInventoryItem({
    required this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.category,
    required this.usageHint,
    this.isProvisionalMatchKit = false,
  });

  final String id;
  final String name;
  final String description;
  final int quantity;
  final ClashInventoryCategory category;
  final ClashInventoryUsageHint usageHint;

  /// Objetos de partido mostrados desde el kit provisional por partido.
  final bool isProvisionalMatchKit;
}

/// Resumen agregado del inventario.
class ClashInventorySummary {
  const ClashInventorySummary({
    required this.totalQuantity,
    required this.quantityByCategory,
  });

  final int totalQuantity;
  final Map<ClashInventoryCategory, int> quantityByCategory;

  int quantityFor(ClashInventoryCategory category) {
    return quantityByCategory[category] ?? 0;
  }
}
