import 'dart:math';

import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';

/// Motor local de tiradas gacha (Fase 23) con pity provisional (Fase 25).
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

  /// Planifica rarezas con pity SR y garantía multi (Fase 25).
  ///
  /// Cada carta suma +1 al contador. Al llegar al umbral se fuerza SR pity
  /// y el contador vuelve a 0. SR natural no reinicia pity.
  ClashGachaPityResult rollWithPity({
    required ClashGachaRarityRates rates,
    required int cardCount,
    required bool applyMultiGuarantee,
    required ClashGachaPityState pityState,
  }) {
    if (cardCount <= 0) {
      return ClashGachaPityResult(
        pityTriggered: false,
        forcedIndex: null,
        stateBefore: pityState,
        stateAfter: pityState,
        slots: const [],
      );
    }

    final stateBefore = pityState;
    var state = pityState;
    final slots = <ClashGachaRollSlot>[];
    int? forcedIndex;
    var pityTriggered = false;

    for (var i = 0; i < cardCount; i++) {
      final nextCount = state.pullsSinceLastPity + 1;
      final nextTotal = state.totalPulls + 1;

      if (nextCount >= state.threshold) {
        slots.add(
          const ClashGachaRollSlot(rarity: ClashRarity.sr, wasPity: true),
        );
        state = state.copyWith(
          pullsSinceLastPity: 0,
          totalPulls: nextTotal,
          pityHits: state.pityHits + 1,
        );
        pityTriggered = true;
        forcedIndex ??= i;
      } else {
        slots.add(ClashGachaRollSlot(rarity: rollRarity(rates)));
        state = state.copyWith(
          pullsSinceLastPity: nextCount,
          totalPulls: nextTotal,
        );
      }
    }

    if (applyMultiGuarantee && cardCount > 1) {
      final hasSr = slots.any((slot) => slot.rarity == ClashRarity.sr);
      if (!hasSr) {
        final lastIndex = slots.length - 1;
        final last = slots[lastIndex];
        slots[lastIndex] = ClashGachaRollSlot(
          rarity: ClashRarity.sr,
          wasPity: last.wasPity,
          wasMultiGuarantee: true,
        );
      }
    }

    return ClashGachaPityResult(
      pityTriggered: pityTriggered,
      forcedIndex: forcedIndex,
      stateBefore: stateBefore,
      stateAfter: state,
      slots: List<ClashGachaRollSlot>.unmodifiable(slots),
    );
  }

  String pickCardId(List<String> pool) {
    if (pool.isEmpty) {
      throw StateError('Pool de gacha vacío');
    }
    return pool[_random.nextInt(pool.length)];
  }
}
