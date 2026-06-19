import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

/// Chip de estado del partido 7v7 (Fase 46).
class ClashMatchStatusChip extends StatelessWidget {
  const ClashMatchStatusChip({required this.state, super.key});

  final MatchState state;

  static bool _isDuelPhase(MatchState state) {
    if (state.isFinished || state.isPausedForHalftime) {
      return false;
    }
    return state.hasPendingDuel || state.lastDuelResolution != null;
  }

  static ({String label, IconData icon, Color? color}) resolve(
    BuildContext context,
    MatchState state,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (state.isFinished) {
      return (
        label: l10n.clashMatchStatusChipFinished,
        icon: Icons.flag_rounded,
        color: theme.colorScheme.outline,
      );
    }
    if (state.isPausedForHalftime) {
      return (
        label: l10n.clashMatchStatusChipHalftime,
        icon: Icons.free_breakfast_rounded,
        color: theme.colorScheme.tertiary,
      );
    }
    if (_isDuelPhase(state)) {
      return (
        label: l10n.clashMatchStatusChipDuel,
        icon: Icons.sports_martial_arts_rounded,
        color: Colors.orange,
      );
    }
    if (state.status == MatchStatus.awaitingCoinToss) {
      return (
        label: l10n.clashMatchPhaseCoinToss,
        icon: Icons.monetization_on_outlined,
        color: theme.colorScheme.secondary,
      );
    }
    if (state.possession == MatchTeamSide.rival) {
      return (
        label: l10n.clashMatchStatusChipRivalPossession,
        icon: Icons.smart_toy_outlined,
        color: Colors.redAccent,
      );
    }
    return (
      label: l10n.clashMatchStatusChipUserPossession,
      icon: Icons.sports_soccer,
      color: theme.colorScheme.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolve(context, state);
    final theme = Theme.of(context);
    final accent = resolved.color ?? theme.colorScheme.primary;

    return Chip(
      avatar: Icon(resolved.icon, size: 16, color: accent),
      label: Text(
        resolved.label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
      side: BorderSide(color: accent.withValues(alpha: 0.45)),
      backgroundColor: accent.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
