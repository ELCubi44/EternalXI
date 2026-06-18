import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';
import 'package:flutter/material.dart';

/// Sección visual de la tienda Clash (Fase 39).
enum ClashShopSection {
  materials,
  techniques,
  evolution,
  tickets;

  static const displayOrder = <ClashShopSection>[
    materials,
    techniques,
    evolution,
    tickets,
  ];

  static ClashShopSection forProduct(ClashShopProduct product) {
    final type = product.grants.first.type;
    return switch (type) {
      ClashShopProductType.expMaterial => ClashShopSection.materials,
      ClashShopProductType.techniqueBook => ClashShopSection.techniques,
      ClashShopProductType.evolutionMaterial => ClashShopSection.evolution,
      ClashShopProductType.ticket => ClashShopSection.tickets,
    };
  }

  IconData get icon => switch (this) {
    ClashShopSection.materials => Icons.auto_stories_rounded,
    ClashShopSection.techniques => Icons.menu_book_rounded,
    ClashShopSection.evolution => Icons.military_tech_rounded,
    ClashShopSection.tickets => Icons.confirmation_number_rounded,
  };

  Color accentColor(ColorScheme scheme) => switch (this) {
    ClashShopSection.materials => scheme.primary,
    ClashShopSection.techniques => scheme.tertiary,
    ClashShopSection.evolution => scheme.secondary,
    ClashShopSection.tickets => scheme.primaryContainer,
  };
}
