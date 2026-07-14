import 'dart:math';

import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';

/// Roba candidatos del mazo de l�nea para un momento de Cadena XI.
class ClashChainDrawEngine {
  const ClashChainDrawEngine._();

  static const defaultDrawCount = 3;

  static List<MatchSquadPlayer> drawCandidates({
    required List<MatchSquadPlayer> squad,
    required List<ClashPosition> trialPositions,
    required List<ClashPosition> preferredPositions,
    required Random random,
    int drawCount = defaultDrawCount,
  }) {
    var pool = squad
        .where((player) => trialPositions.contains(player.position))
        .toList(growable: true);

    if (preferredPositions.isNotEmpty) {
      final preferred = pool
          .where((player) => preferredPositions.contains(player.position))
          .toList(growable: true);
      if (preferred.isNotEmpty) {
        pool = preferred;
      }
    }

    if (pool.isEmpty) {
      pool = squad.toList(growable: true);
    }

    pool.shuffle(random);
    if (pool.length <= drawCount) {
      return List<MatchSquadPlayer>.from(pool);
    }
    return pool.take(drawCount).toList(growable: false);
  }

  /// Indica si el estilo del jugador tendr�a ventaja frente al rival en duelo.
  static bool hasStyleAdvantage({
    required ClashPlayerStyle userStyle,
    required ClashPlayerStyle rivalStyle,
    required bool userIsAttacker,
  }) {
    final matchup = userIsAttacker
        ? compareClashStyles(userStyle, rivalStyle)
        : compareClashStyles(rivalStyle, userStyle);
    return matchup == ClashStyleMatchup.advantage;
  }
}
