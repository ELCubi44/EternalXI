import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Mensajes contextuales del partido 7vs7 (Fase 15).
class ClashMatchStatusMessages {
  const ClashMatchStatusMessages._();

  static ({String primary, String? secondary}) banner(
    AppLocalizations l10n,
    MatchState state,
  ) {
    if (state.isFinished) {
      return (primary: l10n.clashMatchPhaseFinished, secondary: null);
    }

    if (state.isPausedForHalftime) {
      return (
        primary: l10n.clashMatchStatusHalftime,
        secondary: l10n.clashMatchStatusHalftimeHint,
      );
    }

    if (state.lastDuelResolution != null) {
      return (
        primary: l10n.clashMatchStatusDuelResult,
        secondary: l10n.clashMatchStatusDuelResultHint,
      );
    }

    final duel = state.activeDuel;
    if (duel != null && duel.isPending) {
      if (duel.needsDefenderSelection) {
        return (
          primary: l10n.clashMatchStatusPickDefender,
          secondary: l10n.clashMatchStatusDefendRivalHint,
        );
      }
      if (duel.isUserDefending) {
        return (
          primary: duel.type == ClashDuelType.shotVsSave
              ? l10n.clashMatchDefendShotTitle
              : l10n.clashMatchDefendAdvanceTitle,
          secondary: l10n.clashMatchStatusDefendRivalHint,
        );
      }
      return (
        primary: l10n.clashMatchStatusUserDuel,
        secondary: duel.type == ClashDuelType.shotVsSave
            ? l10n.clashMatchStatusUserShotDuelHint
            : l10n.clashMatchStatusUserAdvanceDuelHint,
      );
    }

    if (state.status == MatchStatus.awaitingCoinToss) {
      return (
        primary: l10n.clashMatchCoinTossPrompt,
        secondary: l10n.clashMatchWinTarget,
      );
    }

    if (state.possession == MatchTeamSide.rival) {
      return (
        primary: l10n.clashMatchStatusRivalTurn,
        secondary: l10n.clashMatchStatusRivalTurnHint,
      );
    }

    if (state.possession == MatchTeamSide.user) {
      if (state.isInShootingZone) {
        return (
          primary: l10n.clashMatchStatusBallUser,
          secondary: l10n.clashMatchStatusCanShoot,
        );
      }
      return (
        primary: l10n.clashMatchStatusBallUser,
        secondary: l10n.clashMatchStatusShootNeedArea,
      );
    }

    return (primary: l10n.clashMatchPhasePlaying, secondary: null);
  }
}
