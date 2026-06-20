import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';
import 'package:flutter/material.dart';

/// Iconos Material compartidos para tipos de recompensa Clash (Fase 58).
abstract final class ClashRewardIcon {
  static IconData forKind(ClashRewardKind kind) {
    return switch (kind) {
      ClashRewardKind.coins => Icons.monetization_on_outlined,
      ClashRewardKind.gems => Icons.diamond_outlined,
      ClashRewardKind.expMaterial => Icons.science_outlined,
      ClashRewardKind.techniqueBook => Icons.menu_book_outlined,
      ClashRewardKind.evolutionMaterial => Icons.military_tech_outlined,
      ClashRewardKind.ticket => Icons.confirmation_number_outlined,
      ClashRewardKind.cardMissing ||
      ClashRewardKind.featuredCard => Icons.person_outline,
      ClashRewardKind.cardDuplicate => Icons.copy_outlined,
      ClashRewardKind.starterRoster => Icons.style_outlined,
    };
  }

  static IconData forShopType(ClashShopProductType type) {
    return switch (type) {
      ClashShopProductType.expMaterial => Icons.science_outlined,
      ClashShopProductType.techniqueBook => Icons.menu_book_outlined,
      ClashShopProductType.evolutionMaterial => Icons.military_tech_outlined,
      ClashShopProductType.ticket => Icons.confirmation_number_outlined,
    };
  }

  static IconData forStoryItem() => Icons.inventory_2_outlined;
}
