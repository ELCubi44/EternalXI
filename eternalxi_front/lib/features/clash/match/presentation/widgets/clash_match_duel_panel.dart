import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de duelos Clash: Regate vs Defensa y Tiro vs Parada.
class ClashMatchDuelPanel extends StatelessWidget {
  const ClashMatchDuelPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final match = context.watch<ClashMatchController>();
    final state = match.state;
    if (state == null) {
      return const SizedBox.shrink();
    }

    final resolution = state.lastDuelResolution;
    if (resolution != null) {
      return _DuelResultCard(
        resolution: resolution,
        onContinue: match.dismissDuelResult,
      );
    }

    final duel = state.activeDuel;
    if (duel == null || !duel.isPending) {
      return const SizedBox.shrink();
    }

    return _PendingDuelCard(duel: duel, onResolve: match.resolvePendingDuel);
  }
}

class _PendingDuelCard extends StatelessWidget {
  const _PendingDuelCard({required this.duel, required this.onResolve});

  final ClashDuelState duel;
  final VoidCallback onResolve;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isShot = duel.type == ClashDuelType.shotVsSave;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isShot
              ? Colors.orange.withValues(alpha: 0.6)
              : theme.colorScheme.primary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isShot ? l10n.clashMatchShotDuelTitle : l10n.clashMatchDuelTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ParticipantCard(
                  participant: duel.attacker,
                  accent: theme.colorScheme.primary,
                  statLabel: isShot
                      ? l10n.clashMatchDuelEffectiveShot
                      : l10n.clashMatchDuelEffectiveDribble,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 28,
                ),
                child: Icon(
                  isShot ? Icons.sports_soccer : Icons.flash_on_rounded,
                  color: isShot ? Colors.orange : theme.colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _ParticipantCard(
                  participant: duel.defender,
                  accent: Colors.redAccent,
                  statLabel: isShot
                      ? l10n.clashMatchDuelEffectiveSave
                      : l10n.clashMatchDuelEffectiveDefense,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _styleLabel(context, duel.attackerStyleResult),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onResolve,
            icon: Icon(
              isShot ? Icons.sports_soccer : Icons.directions_run_rounded,
            ),
            label: Text(
              isShot
                  ? l10n.clashMatchDuelNormalShot
                  : l10n.clashMatchDuelNormalDribble,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashMatchDuelSuperTechSoon,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _styleLabel(BuildContext context, ClashDuelStyleResult result) {
    final l10n = context.l10n;
    return switch (result) {
      ClashDuelStyleResult.advantage => l10n.clashMatchDuelStyleAdvantage,
      ClashDuelStyleResult.disadvantage => l10n.clashMatchDuelStyleDisadvantage,
      ClashDuelStyleResult.neutral => l10n.clashMatchDuelStyleNeutral,
    };
  }
}

class _DuelResultCard extends StatelessWidget {
  const _DuelResultCard({required this.resolution, required this.onContinue});

  final ClashDuelResolution resolution;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isShot = resolution.duelType == ClashDuelType.shotVsSave;
    final userWon = resolution.winner == MatchTeamSide.user;

    final headline = isShot
        ? (resolution.isGoal
              ? l10n.clashMatchDuelGoal
              : l10n.clashMatchDuelSave)
        : null;

    final borderColor = isShot
        ? (resolution.isGoal ? Colors.green : Colors.blueAccent)
        : (userWon ? Colors.green : Colors.redAccent);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isShot ? l10n.clashMatchShotDuelTitle : l10n.clashMatchDuelTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (headline != null) ...[
            const SizedBox(height: 8),
            Text(
              headline,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: resolution.isGoal ? Colors.green : Colors.blueAccent,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            resolution.eventText,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.clashMatchDuelScore(
              resolution.attackerScore,
              resolution.defenderScore,
            ),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          if (resolution.resolvedByCoin) ...[
            const SizedBox(height: 4),
            Text(
              l10n.clashMatchDuelCoinTie,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onContinue,
            child: Text(l10n.clashMatchDuelContinue),
          ),
        ],
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  const _ParticipantCard({
    required this.participant,
    required this.accent,
    required this.statLabel,
  });

  final ClashDuelParticipant participant;
  final Color accent;
  final String statLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: accent, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            participant.label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          participant.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          participant.position.displayNameEs,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
        Text(
          participant.style.displayNameEs,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          '$statLabel: ${participant.effectiveStat}',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
