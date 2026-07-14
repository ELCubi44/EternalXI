import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_state.dart';
import 'package:eternal_xi/features/clash/match/domain/match_status.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:flutter/material.dart';

/// Tarjeta del jugador activo en posesión (Fase 46).
class ClashMatchActivePlayerCard extends StatelessWidget {
  const ClashMatchActivePlayerCard({required this.state, super.key});

  final MatchState state;

  MatchSquadPlayer? _activePlayer() {
    if (state.isFinished || state.isPausedForHalftime) {
      return null;
    }
    if (state.status != MatchStatus.playing &&
        state.status != MatchStatus.halftime) {
      return null;
    }

    final duel = state.activeDuel;
    if (duel != null && duel.isPending) {
      final side = duel.attacker.teamSide;
      final index = duel.attacker.squadIndex;
      final squad = state.squadFor(side);
      for (final player in squad) {
        if (player.index == index) {
          return player;
        }
      }
    }

    return state.ballHolderPlayer();
  }

  bool _isRivalActive(MatchSquadPlayer? player) {
    return player?.side == MatchTeamSide.rival;
  }

  @override
  Widget build(BuildContext context) {
    final player = _activePlayer();
    if (player == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isRival = _isRivalActive(player);
    final accent = isRival ? Colors.redAccent : theme.colorScheme.primary;
    final title = isRival
        ? l10n.clashMatchRivalActivePlayerTitle
        : l10n.clashMatchActivePlayerTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.15),
                child: Text(
                  player.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.xiTextSecondary,
                      ),
                    ),
                    Text(
                      player.label,
                      style: theme.textTheme.titleMedium?.copyWith(
                        ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(
                icon: Icons.badge_outlined,
                label: player.position.displayNameEs,
              ),
              _MetaChip(
                icon: Icons.bolt_rounded,
                label: l10n.clashMatchPlayerPowerLabel(player.power),
              ),
              _MetaChip(
                icon: Icons.palette_outlined,
                label: player.style.displayNameEs,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatBar(
                  label: 'PT',
                  current: player.currentPt,
                  max: player.maxPt,
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatBar(
                  label: l10n.clashMatchStaminaLabel,
                  current: player.currentStamina,
                  max: player.maxStamina,
                  color: Colors.lightGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${l10n.clashMatchZoneLabel}: ${state.ballZone.labelEs()}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

class _StatBar extends StatelessWidget {
  const _StatBar({
    required this.label,
    required this.current,
    required this.max,
    required this.color,
  });

  final String label;
  final int current;
  final int max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = max <= 0 ? 0.0 : (current / max).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label $current/$max',
          style: theme.textTheme.labelSmall?.copyWith(
            ),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: color.withValues(alpha: 0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}
