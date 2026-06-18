import 'dart:math';

import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';

/// Motor local de tiradas gacha (Fase 23).
class ClashGachaEngine {
  ClashGachaEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  ClashRarity rollRarity(ClashGachaRarityRates rates) {
    final total = rates.totalPercent;
    if (total <= 0) {
      return ClashRarity.n;
    }
    var roll = _random.nextInt(total);
    for (final entry in rates.weightedEntries) {
      if (entry.$2 <= 0) {
        continue;
      }
      if (roll < entry.$2) {
        return entry.$1;
      }
      roll -= entry.$2;
    }
    return ClashRarity.n;
  }

  List<ClashRarity> rollMulti({
    required ClashGachaRarityRates rates,
    required int count,
    bool guaranteeSrOnLast = true,
  }) {
    if (count <= 0) {
      return const [];
    }
    if (count == 1) {
      return [rollRarity(rates)];
    }

    final results = <ClashRarity>[
      for (var i = 0; i < count - 1; i++) rollRarity(rates),
    ];
    final hasSr = results.any((rarity) => rarity == ClashRarity.sr);
    if (guaranteeSrOnLast && !hasSr) {
      results.add(ClashRarity.sr);
    } else {
      results.add(rollRarity(rates));
    }
    return results;
  }

  String pickCardId(List<String> pool) {
    if (pool.isEmpty) {
      throw StateError('Pool de gacha vacío');
    }
    return pool[_random.nextInt(pool.length)];
  }
}
