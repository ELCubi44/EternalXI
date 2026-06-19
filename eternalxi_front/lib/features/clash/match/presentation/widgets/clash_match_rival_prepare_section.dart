import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_player.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_power_comparison.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:flutter/material.dart';

/// Ficha rival, comparativa de potencia y alineación expandible (Fase 43).
class ClashMatchRivalPrepareSection extends StatelessWidget {
  const ClashMatchRivalPrepareSection({
    required this.ownPower,
    this.rivalTeam,
    this.fallbackRecommendedPower,
    super.key,
  });

  final int ownPower;
  final ClashRivalTeam? rivalTeam;
  final int? fallbackRecommendedPower;

  int? get _comparisonReference =>
      rivalTeam?.recommendedPower ?? fallbackRecommendedPower;

  @override
  Widget build(BuildContext context) {
    final comparisonReference = _comparisonReference;
    if (rivalTeam == null && comparisonReference == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RivalCard(
          rivalTeam: rivalTeam,
          fallbackRecommendedPower: fallbackRecommendedPower,
        ),
        if (comparisonReference != null) ...[
          const SizedBox(height: 16),
          _PowerComparisonCard(
            ownPower: ownPower,
            referencePower: comparisonReference,
            displayedRivalPower: rivalTeam?.totalPower ?? comparisonReference,
          ),
        ],
        if (rivalTeam != null) ...[
          const SizedBox(height: 8),
          _RivalLineupExpansion(team: rivalTeam!),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RivalCard extends StatelessWidget {
  const _RivalCard({
    required this.rivalTeam,
    required this.fallbackRecommendedPower,
  });

  final ClashRivalTeam? rivalTeam;
  final int? fallbackRecommendedPower;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final team = rivalTeam;
    final name = team?.name ?? l10n.clashMatchPrepareStandardRival;
    final description = team?.description;
    final recommended = team?.recommendedPower ?? fallbackRecommendedPower;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clashMatchPrepareRival,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: context.xiTextSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
                height: 1.4,
              ),
            ),
          ],
          if (team != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DifficultyChip(difficulty: team.difficulty),
                if (recommended != null)
                  Chip(
                    label: Text(
                      '${l10n.clashMatchPrepareRecommendedPower}: $recommended',
                    ),
                    backgroundColor: context.xiBackground,
                    side: BorderSide(color: context.xiDivider),
                    visualDensity: VisualDensity.compact,
                  ),
                Chip(
                  label: Text(
                    l10n.clashMatchPrepareRivalPlayersCount(
                      team.lineup7v7.length,
                      ClashPosition.values.length,
                    ),
                  ),
                  backgroundColor: context.xiBackground,
                  side: BorderSide(color: context.xiDivider),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoRow(
              label: l10n.clashMatchPrepareRivalPower,
              value: '${team.totalPower}',
            ),
            if (team.predominantStyles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.clashMatchPreparePredominantStyles,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final style in team.predominantStyles.take(3))
                    Chip(
                      label: Text(style.displayNameEs),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: context.xiBackground,
                      side: BorderSide(color: context.xiDivider),
                    ),
                ],
              ),
            ],
          ] else if (recommended != null) ...[
            const SizedBox(height: 12),
            _InfoRow(
              label: l10n.clashMatchPrepareRecommendedPower,
              value: '$recommended',
            ),
          ],
        ],
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  const _DifficultyChip({required this.difficulty});

  final int difficulty;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Chip(
      label: Text(l10n.clashMatchPrepareDifficultyChip(difficulty)),
      backgroundColor: _chipColor(difficulty).withValues(alpha: 0.15),
      side: BorderSide(color: _chipColor(difficulty).withValues(alpha: 0.45)),
      visualDensity: VisualDensity.compact,
    );
  }

  Color _chipColor(int level) {
    return switch (level) {
      1 => Colors.green,
      2 => Colors.orange,
      3 => Colors.redAccent,
      _ => Colors.blueGrey,
    };
  }
}

class _PowerComparisonCard extends StatelessWidget {
  const _PowerComparisonCard({
    required this.ownPower,
    required this.referencePower,
    required this.displayedRivalPower,
  });

  final int ownPower;
  final int referencePower;
  final int displayedRivalPower;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final difference = ClashRivalPowerComparison.difference(
      ownPower,
      referencePower,
    );
    final status = ClashRivalPowerComparison.evaluate(
      ownPower: ownPower,
      referencePower: referencePower,
    );
    final diffLabel = difference >= 0 ? '+$difference' : '$difference';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: l10n.clashMatchPrepareOwnPower, value: '$ownPower'),
          _InfoRow(
            label: l10n.clashMatchPrepareRivalPower,
            value: '$displayedRivalPower',
          ),
          _InfoRow(
            label: l10n.clashMatchPreparePowerDifference,
            value: diffLabel,
          ),
          const SizedBox(height: 10),
          _MatchupStatusChip(status: status),
        ],
      ),
    );
  }
}

class _MatchupStatusChip extends StatelessWidget {
  const _MatchupStatusChip({required this.status});

  final ClashRivalPowerMatchupStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, color, icon) = switch (status) {
      ClashRivalPowerMatchupStatus.clearAdvantage => (
        l10n.clashMatchPreparePowerAdvantage,
        Colors.green,
        Icons.trending_up_rounded,
      ),
      ClashRivalPowerMatchupStatus.even => (
        l10n.clashMatchPreparePowerEven,
        Colors.blue,
        Icons.balance_rounded,
      ),
      ClashRivalPowerMatchupStatus.disadvantage => (
        l10n.clashMatchPreparePowerDisadvantage,
        Colors.orange,
        Icons.trending_down_rounded,
      ),
      ClashRivalPowerMatchupStatus.veryHard => (
        l10n.clashMatchPreparePowerVeryHard,
        Colors.redAccent,
        Icons.warning_amber_rounded,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RivalLineupExpansion extends StatelessWidget {
  const _RivalLineupExpansion({required this.team});

  final ClashRivalTeam team;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final players = [...team.lineup7v7]
      ..sort(
        (a, b) => ClashPosition.values
            .indexOf(a.position)
            .compareTo(ClashPosition.values.indexOf(b.position)),
      );

    return Material(
      color: context.xiCardSurface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          l10n.clashMatchPrepareViewRivalLineup,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [
          for (final player in players) _RivalPlayerRow(player: player),
        ],
      ),
    );
  }
}

class _RivalPlayerRow extends StatelessWidget {
  const _RivalPlayerRow({required this.player});

  final ClashRivalPlayer player;

  @override
  Widget build(BuildContext context) {
    final techniqueNames = player.superTechniques
        .map((technique) => technique.name)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${player.position.displayNameEs} · ${player.name}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '${player.style.displayNameEs} · '
            '${player.rarity.toJson().toUpperCase()} Lv${player.level} · '
            '${player.power}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
          if (techniqueNames.isNotEmpty)
            Text(
              techniqueNames,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: context.xiTextSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
