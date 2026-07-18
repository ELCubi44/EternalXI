import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_status.dart';
import 'package:flutter/material.dart';

/// Elemento de recompensa listo para pintar en UI (Fase 58).
class ClashRewardDisplayItem {
  const ClashRewardDisplayItem({
    required this.label,
    this.icon,
    this.iconAsset,
    this.quantity,
    this.detail,
    this.status = ClashRewardDisplayStatus.none,
  }) : assert(icon != null || iconAsset != null);

  final IconData? icon;
  /// Asset PNG (p. ej. balón de cristal) en lugar de Icon Material.
  final String? iconAsset;
  final String label;
  final int? quantity;
  final String? detail;
  final ClashRewardDisplayStatus status;

  bool get showQuantity => quantity != null && quantity! > 0;
}
