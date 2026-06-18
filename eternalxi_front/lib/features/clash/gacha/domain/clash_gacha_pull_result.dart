import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_error.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';

class ClashGachaPullResultItem {
  const ClashGachaPullResultItem({
    required this.cardId,
    required this.cardName,
    required this.rarity,
    required this.isNew,
    required this.isDuplicate,
    required this.upgradedRarity,
    required this.duplicateCopiesAfter,
    this.wasPity = false,
    this.wasMultiGuarantee = false,
  });

  final String cardId;
  final String cardName;
  final ClashRarity rarity;
  final bool isNew;
  final bool isDuplicate;
  final bool upgradedRarity;
  final int duplicateCopiesAfter;
  final bool wasPity;
  final bool wasMultiGuarantee;
}

class ClashGachaPullResult {
  const ClashGachaPullResult({
    required this.bannerId,
    required this.pullType,
    required this.spentGems,
    required this.results,
    required this.createdAt,
    required this.remainingGems,
    this.pityTriggered = false,
  });

  final String bannerId;
  final ClashGachaPullType pullType;
  final int spentGems;
  final List<ClashGachaPullResultItem> results;
  final DateTime createdAt;
  final int remainingGems;
  final bool pityTriggered;
}

class ClashGachaPullOutcome {
  const ClashGachaPullOutcome({this.result, this.error});

  final ClashGachaPullResult? result;
  final ClashGachaPullError? error;

  bool get succeeded => result != null && error == null;
}
