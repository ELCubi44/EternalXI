import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_event.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Motivo simple de objetivo no cumplido (solo UI, Fase 48).
class ClashMatchObjectiveFailureHint {
  const ClashMatchObjectiveFailureHint._();

  static String? resolve({
    required AppLocalizations l10n,
    required ClashMatchObjective objective,
    required MatchState state,
    required bool userWon,
    required bool completed,
  }) {
    if (completed || !userWon) {
      return null;
    }

    return switch (objective.type) {
      ClashMatchObjectiveType.cleanSheet when state.score.rival > 0 =>
        l10n.clashMatchObjectiveFailConcededGoal,
      ClashMatchObjectiveType.scoreWithShotTechnique
          when !_hasUserShotTechniqueGoal(state) =>
        l10n.clashMatchObjectiveFailNoShotTechnique,
      _ => null,
    };
  }

  static bool _hasUserShotTechniqueGoal(MatchState state) {
    for (final event in state.eventLog) {
      if (event.type != MatchEventType.goal) {
        continue;
      }
      final details = event.goalDetails;
      if (details == null || details.scorer != MatchTeamSide.user) {
        continue;
      }
      if (details.techniqueType == ClashTechniqueType.shot) {
        return true;
      }
    }
    return false;
  }
}
