import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_participant.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_resolution.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_state.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_style_result.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_technique_rules.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/match/presentation/controllers/clash_match_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Panel de duelos Clash: Regate vs Defensa y Tiro vs Parada (Fase 9–11).
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

    if (duel.needsDefenderSelection) {
      return _DefenderSelectionCard(
        state: state,
        duel: duel,
        onSelectDefender: match.selectManualDefender,
      );
    }

    final attackerPlayer = _playerFromState(state, duel.attacker);
    final defenderPlayer = _playerFromState(state, duel.defender);

    if (duel.isUserDefending) {
      return _ManualDefenseCard(
        duel: duel,
        attackerPlayer: attackerPlayer,
        defenderPlayer: defenderPlayer,
        onResolveNormal: () => match.resolveManualDefense(),
        onResolveTechnique: (id) => match.resolveManualDefense(techniqueId: id),
      );
    }

    return _PendingDuelCard(
      duel: duel,
      attackerPlayer: attackerPlayer,
      onResolveNormal: () => match.resolvePendingDuel(),
      onResolveTechnique: (id) => match.resolvePendingDuel(techniqueId: id),
    );
  }

  static MatchSquadPlayer? _playerFromState(
    MatchState state,
    ClashDuelParticipant participant,
  ) {
    final squad = state.squadFor(participant.teamSide);
    final index = participant.squadIndex;
    if (index < 0 || index >= squad.length) {
      return null;
    }
    return squad[index];
  }
}

class _DefenderSelectionCard extends StatelessWidget {
  const _DefenderSelectionCard({
    required this.state,
    required this.duel,
    required this.onSelectDefender,
  });

  final MatchState state;
  final ClashDuelState duel;
  final ValueChanged<int> onSelectDefender;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final indices = duel.defenderCandidateIndices ?? const <int>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchDefendSelectDefenderTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.clashMatchBallHolder(duel.attacker.label),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ...indices.map((index) {
            final player = state.userSquad.firstWhere(
              (p) => p.index == index,
              orElse: () => state.userSquad.first,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => onSelectDefender(index),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${player.label} · ${player.position.displayNameEs}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l10n.clashMatchDefendCandidateMeta(
                        player.effectiveDefense,
                        player.currentPt,
                        player.currentStamina,
                        player.style.displayNameEs,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ManualDefenseCard extends StatelessWidget {
  const _ManualDefenseCard({
    required this.duel,
    required this.attackerPlayer,
    required this.defenderPlayer,
    required this.onResolveNormal,
    required this.onResolveTechnique,
  });

  final ClashDuelState duel;
  final MatchSquadPlayer? attackerPlayer;
  final MatchSquadPlayer? defenderPlayer;
  final VoidCallback onResolveNormal;
  final ValueChanged<String> onResolveTechnique;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isShot = duel.type == ClashDuelType.shotVsSave;
    final techniques = defenderPlayer == null
        ? const <ClashSuperTechnique>[]
        : ClashDuelTechniqueRules.compatibleForDefender(
            defenderPlayer!,
            duel.type,
          );
    final currentPt = defenderPlayer?.currentPt ?? 0;
    final rivalAttack = _rivalAttackLabel(context, attackerPlayer, duel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isShot
              ? Colors.orange.withValues(alpha: 0.6)
              : Colors.blueAccent.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isShot
                ? l10n.clashMatchDefendShotTitle
                : l10n.clashMatchDefendAdvanceTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rivalAttack,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ParticipantCard(
                  participant: duel.attacker,
                  accent: Colors.redAccent,
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
                  color: isShot ? Colors.orange : Colors.blueAccent,
                ),
              ),
              Expanded(
                child: _ParticipantCard(
                  participant: duel.defender,
                  accent: theme.colorScheme.primary,
                  statLabel: isShot
                      ? l10n.clashMatchDuelEffectiveSave
                      : l10n.clashMatchDuelEffectiveDefense,
                  currentPt: currentPt,
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
            onPressed: onResolveNormal,
            icon: Icon(isShot ? Icons.back_hand_rounded : Icons.shield_rounded),
            label: Text(
              isShot
                  ? l10n.clashMatchDefendNormalSave
                  : l10n.clashMatchDefendNormalDefense,
            ),
          ),
          if (techniques.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.clashMatchDuelSuperTechniques,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...techniques.map(
              (technique) => _TechniqueButton(
                technique: technique,
                currentPt: currentPt,
                onTap: () => onResolveTechnique(technique.id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _rivalAttackLabel(
    BuildContext context,
    MatchSquadPlayer? attacker,
    ClashDuelState duel,
  ) {
    final l10n = context.l10n;
    final choice = duel.presetAttackerChoice;
    if (choice == null || choice.isNormal) {
      return l10n.clashMatchRivalAttackNormal;
    }
    if (attacker == null) {
      return l10n.clashMatchRivalAttackTechnique('—');
    }
    final technique = ClashDuelTechniqueRules.findTechnique(
      attacker,
      choice.techniqueId,
    );
    return l10n.clashMatchRivalAttackTechnique(technique?.name ?? '—');
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

class _PendingDuelCard extends StatelessWidget {
  const _PendingDuelCard({
    required this.duel,
    required this.attackerPlayer,
    required this.onResolveNormal,
    required this.onResolveTechnique,
  });

  final ClashDuelState duel;
  final MatchSquadPlayer? attackerPlayer;
  final VoidCallback onResolveNormal;
  final ValueChanged<String> onResolveTechnique;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isShot = duel.type == ClashDuelType.shotVsSave;
    final techniques = attackerPlayer == null
        ? const <ClashSuperTechnique>[]
        : ClashDuelTechniqueRules.compatibleForAttacker(
            attackerPlayer!,
            duel.type,
          );
    final currentPt = attackerPlayer?.currentPt ?? 0;

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
                  currentPt: currentPt,
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
            onPressed: onResolveNormal,
            icon: Icon(
              isShot ? Icons.sports_soccer : Icons.directions_run_rounded,
            ),
            label: Text(
              isShot
                  ? l10n.clashMatchDuelNormalShot
                  : l10n.clashMatchDuelNormalDribble,
            ),
          ),
          if (techniques.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.clashMatchDuelSuperTechniques,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ...techniques.map(
              (technique) => _TechniqueButton(
                technique: technique,
                currentPt: currentPt,
                onTap: () => onResolveTechnique(technique.id),
              ),
            ),
          ],
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

class _TechniqueButton extends StatelessWidget {
  const _TechniqueButton({
    required this.technique,
    required this.currentPt,
    required this.onTap,
  });

  final ClashSuperTechnique technique;
  final int currentPt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canAfford = technique.canBeUsed(currentPt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton(
        onPressed: canAfford ? onTap : null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          alignment: Alignment.centerLeft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              technique.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.clashMatchDuelTechniqueMeta(
                technique.type.displayNameEs,
                technique.style.displayNameEs,
                technique.effectivePower,
                technique.ptCost,
                technique.level.name.toUpperCase(),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
            Text(
              l10n.clashMatchDuelCurrentPt(currentPt),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!canAfford)
              Text(
                l10n.clashMatchDuelInsufficientPt,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
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
          if (resolution.attackerTechniqueName != null ||
              resolution.defenderTechniqueName != null) ...[
            const SizedBox(height: 6),
            if (resolution.attackerTechniqueName != null)
              Text(
                l10n.clashMatchDuelTechniqueUsed(
                  resolution.attackerTechniqueName!,
                  resolution.attackerPtSpent,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            if (resolution.defenderTechniqueName != null)
              Text(
                l10n.clashMatchDuelDefenderTechnique(
                  resolution.defenderTechniqueName!,
                  resolution.defenderPtSpent,
                ),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
          ],
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
    this.currentPt,
  });

  final ClashDuelParticipant participant;
  final Color accent;
  final String statLabel;
  final int? currentPt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

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
        if (currentPt != null) ...[
          const SizedBox(height: 2),
          Text(
            l10n.clashMatchDuelCurrentPt(currentPt!),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
