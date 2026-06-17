import 'package:eternal_xi/features/clash/match/domain/clash_duel_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_action.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_rival_ai_decision.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pass_option.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_possession_math.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// IA básica de posesión rival: pase, avance, duelo y tiro (Fase 13).
class ClashRivalAiEngine {
  const ClashRivalAiEngine._();

  static const int _minPassPercent = 58;
  static const int _safePassPercent = 62;

  /// Evalúa la mejor acción sin mutar el estado.
  static ClashRivalAiDecision decide(MatchState state) {
    if (state.possession != MatchTeamSide.rival) {
      return const ClashRivalAiDecision(
        action: ClashRivalAiAction.advance,
        summary: 'Sin posesión rival',
      );
    }

    final holder = state.ballHolderPlayer();
    if (holder == null) {
      return const ClashRivalAiDecision(
        action: ClashRivalAiAction.advance,
        summary: 'Rival avanza',
      );
    }

    if (ClashDuelEngine.canShoot(state)) {
      return ClashRivalAiDecision(
        action: ClashRivalAiAction.shoot,
        summary: '${holder.label} se planta para tirar',
      );
    }

    final passOptions = MatchPossessionEngine.passOptions(state);
    final bestPass = _bestPassOption(state, holder, passOptions);
    final advanceScore = _scoreAdvance(state, holder);
    final passScore = bestPass == null ? -1000.0 : bestPass.$2;

    if (bestPass != null && passScore >= advanceScore) {
      final option = bestPass.$1;
      return ClashRivalAiDecision(
        action: ClashRivalAiAction.pass,
        summary: 'Rival pasa a ${option.targetName}',
        passTargetIndex: option.targetIndex,
        passTargetLabel: option.targetName,
      );
    }

    return ClashRivalAiDecision(
      action: ClashRivalAiAction.advance,
      summary: '${holder.label} avanza con el balón',
    );
  }

  /// Una pulsación = una decisión ejecutada con las reglas reales del partido.
  static ({MatchState state, ClashRivalAiDecision decision}) executeTurn(
    MatchState state,
    MatchChanceResolver chance,
  ) {
    if (state.possession != MatchTeamSide.rival ||
        state.isFinished ||
        state.isPausedForHalftime) {
      return (
        state: state,
        decision: const ClashRivalAiDecision(
          action: ClashRivalAiAction.advance,
          summary: 'Turno rival no disponible',
        ),
      );
    }

    var working = state;
    if (working.lastDuelResolution != null) {
      working = ClashDuelEngine.dismissDuelResult(working);
    }

    final decision = decide(working);
    final next = switch (decision.action) {
      ClashRivalAiAction.shoot => _executeShoot(working, chance, decision),
      ClashRivalAiAction.advance => _executeAdvance(working, chance, decision),
      ClashRivalAiAction.pass => _executePass(working, chance, decision),
    };

    return (state: next, decision: decision);
  }

  static MatchState _executeShoot(
    MatchState state,
    MatchChanceResolver chance,
    ClashRivalAiDecision decision,
  ) {
    var next = ClashDuelEngine.beginShot(state);
    if (next.activeDuel != null) {
      next = ClashDuelEngine.resolveRivalAutoDuel(next, chance);
    }
    return _appendRivalActionEvent(next, decision.summary);
  }

  static MatchState _executeAdvance(
    MatchState state,
    MatchChanceResolver chance,
    ClashRivalAiDecision decision,
  ) {
    var next = ClashDuelEngine.beginRivalAdvance(state, chance);
    if (next.activeDuel?.isPending ?? false) {
      next = ClashDuelEngine.resolveRivalAutoDuel(next, chance);
      return _appendRivalActionEvent(
        next,
        '${decision.summary} — duelo resuelto',
      );
    }
    return _appendRivalActionEvent(next, decision.summary);
  }

  static MatchState _executePass(
    MatchState state,
    MatchChanceResolver chance,
    ClashRivalAiDecision decision,
  ) {
    final target = decision.passTargetIndex;
    if (target == null) {
      return state;
    }
    final next = MatchPossessionEngine.executePass(state, target, chance);
    return _appendRivalActionEvent(next, decision.summary);
  }

  static MatchState _appendRivalActionEvent(MatchState state, String summary) {
    return state.copyWith(
      eventLog: [
        ...state.eventLog,
        MatchEvent(type: MatchEventType.rivalAction, message: summary),
      ],
    );
  }

  static (MatchPassOption, double)? _bestPassOption(
    MatchState state,
    MatchSquadPlayer holder,
    List<MatchPassOption> options,
  ) {
    (MatchPassOption, double)? best;
    for (final option in options) {
      final score = _scorePass(state, holder, option);
      if (score < _minPassPercent) {
        continue;
      }
      if (best == null || score > best.$2) {
        best = (option, score);
      }
    }
    return best;
  }

  static double _scorePass(
    MatchState state,
    MatchSquadPlayer holder,
    MatchPassOption option,
  ) {
    var score = option.successPercent.toDouble();

    final progress = state.ballZone.order - option.approximateZone.order;
    if (progress > 0) {
      score += progress * 11;
    } else if (progress < 0) {
      score += progress * 7;
    }

    score += option.targetPower * 0.12;

    if (MatchPossessionMath.isDefenseToStriker(
      holder.position,
      option.targetPosition,
    )) {
      if (option.successPercent < _safePassPercent) {
        score -= 45;
      } else {
        score -= 12;
      }
    }

    if (state.pressure >= 55) {
      score += 8;
    }

    if (state.ballZone.order <= 1) {
      score -= 18;
    }

    if (option.successPercent >= _safePassPercent) {
      score += 14;
    }

    final distance = MatchPossessionMath.logicalDistance(
      holder.index,
      option.targetIndex,
    );
    if (distance >= 4) {
      score -= 22;
    }

    return score;
  }

  static double _scoreAdvance(MatchState state, MatchSquadPlayer holder) {
    if (ClashDuelEngine.canShoot(state)) {
      return -1000;
    }

    var score = MatchPossessionEngine.advanceChance(state).toDouble();
    score += holder.effectiveDribble * 0.22;

    if (state.ballZone == MatchBallZone.rivalMidfield ||
        state.ballZone == MatchBallZone.midfield) {
      score += 12;
    }

    if (state.pressure >= 65) {
      score -= 10;
    }

    if (holder.currentStamina < 35) {
      score -= 15;
    }

    return score;
  }
}
