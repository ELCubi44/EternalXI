import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

/// Encabezado de fin de partido 7v7 (Fase 48).
class ClashMatchEndHeader extends StatelessWidget {
  const ClashMatchEndHeader({required this.state, this.subtitle, super.key});

  final MatchState state;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userWon = state.winner == MatchTeamSide.user;
    final accent = userWon ? Colors.green : Colors.redAccent;

    return Column(
      children: [
        Icon(
          userWon ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied,
          size: 48,
          color: accent,
        ),
        const SizedBox(height: 8),
        Text(
          userWon ? l10n.clashMatchVictory : l10n.clashMatchDefeat,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: accent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.clashMatchEndScoreYouRival(state.score.user, state.score.rival),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.clashMatchWinTarget,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
