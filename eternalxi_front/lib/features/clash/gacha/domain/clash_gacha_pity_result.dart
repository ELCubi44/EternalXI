import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';

/// Una carta planificada en una tirada con metadatos de pity/garantía.
class ClashGachaRollSlot {
  const ClashGachaRollSlot({
    required this.rarity,
    this.wasPity = false,
    this.wasMultiGuarantee = false,
  });

  final ClashRarity rarity;
  final bool wasPity;
  final bool wasMultiGuarantee;
}

/// Resultado del cálculo de pity en una tirada (Fase 25).
class ClashGachaPityResult {
  const ClashGachaPityResult({
    required this.pityTriggered,
    required this.forcedIndex,
    required this.stateBefore,
    required this.stateAfter,
    required this.slots,
  });

  final bool pityTriggered;
  final int? forcedIndex;
  final ClashGachaPityState stateBefore;
  final ClashGachaPityState stateAfter;
  final List<ClashGachaRollSlot> slots;
}
