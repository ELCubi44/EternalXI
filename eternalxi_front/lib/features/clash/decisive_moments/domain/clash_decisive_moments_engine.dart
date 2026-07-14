import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_math.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_technique_selector.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';

/// Resoluci�n de duelos y selecci�n autom�tica de rivales para momentos decisivos.
class ClashDecisiveMomentsEngine {
  const ClashDecisiveMomentsEngine._();

  static MatchSquadPlayer pickRivalAttacker({
    required List<MatchSquadPlayer> rivalSquad,
    required ClashDecisiveMoment moment,
  }) {
    if (moment.duelType == ClashDuelType.shotVsSave) {
      return _bestBy(rivalSquad, (p) => p.effectiveShot);
    }
    return _bestBy(rivalSquad, (p) => p.effectiveDribble);
  }

  static MatchSquadPlayer pickRivalDefender({
    required List<MatchSquadPlayer> rivalSquad,
    required ClashDecisiveMoment moment,
  }) {
    if (moment.duelType == ClashDuelType.shotVsSave) {
      final gk = rivalSquad.where(
        (p) => p.position == ClashPosition.goalkeeper,
      );
      if (gk.isNotEmpty) {
        return _bestBy(gk.toList(), (p) => p.effectiveSave);
      }
      return _bestBy(rivalSquad, (p) => p.effectiveSave);
    }
    return _bestBy(rivalSquad, (p) => p.effectiveDefense);
  }

  static ClashDuelResolution resolve({
    required ClashDecisiveMoment moment,
    required MatchSquadPlayer attacker,
    required MatchSquadPlayer defender,
    required MatchScore score,
    required MatchChanceResolver chance,
    ClashSuperTechnique? userTechnique,
    bool userIsDefender = false,
    int pressure = 35,
  }) {
    final attackerParticipant = _attackerParticipant(attacker, moment.duelType);
    final defenderParticipant = _defenderParticipant(defender, moment.duelType);

    ClashSuperTechnique? attackerTechnique;
    ClashSuperTechnique? defenderTechnique;

    if (moment.isUserAttacking) {
      attackerTechnique = userTechnique;
      final rivalChoice = ClashRivalTechniqueSelector.selectDefender(
        player: defender,
        duelType: moment.duelType,
        effectiveBaseStat: moment.duelType == ClashDuelType.shotVsSave
            ? defender.effectiveSave
            : defender.effectiveDefense,
        opponentStyle: attacker.style,
        pressure: pressure,
        score: score,
        playerSide: defender.side,
      );
      if (rivalChoice.usesTechnique) {
        defenderTechnique = ClashDuelTechniqueRules.findTechnique(
          defender,
          rivalChoice.techniqueId,
        );
      }
    } else {
      final rivalChoice = ClashRivalTechniqueSelector.selectAttacker(
        player: attacker,
        duelType: moment.duelType,
        effectiveBaseStat: moment.duelType == ClashDuelType.shotVsSave
            ? attacker.effectiveShot
            : attacker.effectiveDribble,
        opponentStyle: defender.style,
        ballZone: moment.ballZone,
        score: score,
        playerSide: attacker.side,
      );
      if (rivalChoice.usesTechnique) {
        attackerTechnique = ClashDuelTechniqueRules.findTechnique(
          attacker,
          rivalChoice.techniqueId,
        );
      }
      if (userIsDefender) {
        defenderTechnique = userTechnique;
      }
    }

    if (moment.duelType == ClashDuelType.shotVsSave) {
      return ClashDuelMath.resolveShotVsSave(
        shooter: attackerParticipant,
        goalkeeper: defenderParticipant,
        ballZone: moment.ballZone,
        pressure: pressure,
        chance: chance,
        shooterTechnique: attackerTechnique,
        goalkeeperTechnique: defenderTechnique,
      );
    }

    return ClashDuelMath.resolveDribbleVsDefense(
      attacker: attackerParticipant,
      defender: defenderParticipant,
      ballZone: moment.ballZone,
      pressure: pressure,
      chance: chance,
      attackerTechnique: attackerTechnique,
      defenderTechnique: defenderTechnique,
    );
  }

  static String chronicleFor(ClashDuelResolution resolution) {
    if (resolution.isGoal) {
      return '�GOOOOL! ${resolution.eventText}';
    }
    if (resolution.isSave) {
      return 'Parada clave. ${resolution.eventText}';
    }
    if (resolution.duelType == ClashDuelType.dribbleVsDefense) {
      if (resolution.attackerWon) {
        return 'Sigue la jugada. ${resolution.eventText}';
      }
      return 'Bal�n recuperado. ${resolution.eventText}';
    }
    return resolution.eventText;
  }

  static ClashDuelParticipant _attackerParticipant(
    MatchSquadPlayer player,
    ClashDuelType type,
  ) {
    if (type == ClashDuelType.shotVsSave) {
      return ClashDuelParticipant.fromSquadPlayer(
        player,
        baseStat: player.baseStats.shot,
        effectiveStat: player.effectiveShot,
      );
    }
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.dribble,
      effectiveStat: player.effectiveDribble,
    );
  }

  static ClashDuelParticipant _defenderParticipant(
    MatchSquadPlayer player,
    ClashDuelType type,
  ) {
    if (type == ClashDuelType.shotVsSave) {
      return ClashDuelParticipant.fromSquadPlayer(
        player,
        baseStat: player.baseStats.save,
        effectiveStat: player.effectiveSave,
      );
    }
    return ClashDuelParticipant.fromSquadPlayer(
      player,
      baseStat: player.baseStats.defense,
      effectiveStat: player.effectiveDefense,
    );
  }

  static MatchSquadPlayer _bestBy(
    List<MatchSquadPlayer> players,
    int Function(MatchSquadPlayer) stat,
  ) {
    return players.reduce((a, b) => stat(a) >= stat(b) ? a : b);
  }
}
