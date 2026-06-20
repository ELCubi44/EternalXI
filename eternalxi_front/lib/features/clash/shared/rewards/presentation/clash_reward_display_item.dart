import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_status.dart';
import 'package:flutter/material.dart';

/// Elemento de recompensa listo para pintar en UI (Fase 58).
class ClashRewardDisplayItem {
  const ClashRewardDisplayItem({
    required this.icon,
    required this.label,
    this.quantity,
    this.detail,
    this.status = ClashRewardDisplayStatus.none,
  });

  final IconData icon;
  final String label;
  final int? quantity;
  final String? detail;
  final ClashRewardDisplayStatus status;

  bool get showQuantity => quantity != null && quantity! > 0;
}
