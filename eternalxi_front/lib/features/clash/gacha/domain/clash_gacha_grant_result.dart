import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Resultado de conceder una carta por gacha (Fase 23).
class ClashGachaGrantResult {
  const ClashGachaGrantResult({
    required this.cardId,
    required this.grantedRarity,
    required this.isNew,
    required this.isDuplicate,
    required this.upgradedRarity,
    required this.duplicateCopiesAfter,
  });

  final String cardId;
  final ClashRarity grantedRarity;
  final bool isNew;
  final bool isDuplicate;
  final bool upgradedRarity;
  final int duplicateCopiesAfter;
}
