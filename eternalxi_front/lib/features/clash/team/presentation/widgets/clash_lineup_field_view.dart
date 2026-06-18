import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';
import 'package:eternal_xi/features/clash/team/presentation/controllers/clash_lineups_controller.dart';
import 'package:eternal_xi/features/clash/team/presentation/widgets/clash_lineup_slot_tile.dart';
import 'package:flutter/material.dart';

class ClashLineupFieldView extends StatelessWidget {
  const ClashLineupFieldView({
    required this.lineup,
    required this.controller,
    required this.onSlotTap,
    super.key,
  });

  final ClashLineup7v7 lineup;
  final ClashLineupsController controller;
  final ValueChanged<ClashPosition> onSlotTap;

  static const _attack = [ClashPosition.striker, ClashPosition.winger];
  static const _midfield = [
    ClashPosition.attackingMidfielder,
    ClashPosition.defensiveMidfielder,
  ];
  static const _defense = [ClashPosition.centreBack, ClashPosition.fullBack];
  static const _goalkeeper = [ClashPosition.goalkeeper];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.06),
            context.xiSurfaceInset,
            theme.colorScheme.tertiary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ZoneSection(
            title: context.l10n.clashLineupZoneAttack,
            accent: theme.colorScheme.error.withValues(alpha: 0.85),
            positions: _attack,
            lineup: lineup,
            controller: controller,
            onSlotTap: onSlotTap,
          ),
          const SizedBox(height: 10),
          _ZoneSection(
            title: context.l10n.clashLineupZoneMidfield,
            accent: theme.colorScheme.primary,
            positions: _midfield,
            lineup: lineup,
            controller: controller,
            onSlotTap: onSlotTap,
          ),
          const SizedBox(height: 10),
          _ZoneSection(
            title: context.l10n.clashLineupZoneDefense,
            accent: theme.colorScheme.secondary,
            positions: _defense,
            lineup: lineup,
            controller: controller,
            onSlotTap: onSlotTap,
          ),
          const SizedBox(height: 10),
          _ZoneSection(
            title: context.l10n.clashLineupZoneGoalkeeper,
            accent: theme.colorScheme.tertiary,
            positions: _goalkeeper,
            lineup: lineup,
            controller: controller,
            onSlotTap: onSlotTap,
          ),
        ],
      ),
    );
  }
}

class _ZoneSection extends StatelessWidget {
  const _ZoneSection({
    required this.title,
    required this.accent,
    required this.positions,
    required this.lineup,
    required this.controller,
    required this.onSlotTap,
  });

  final String title;
  final Color accent;
  final List<ClashPosition> positions;
  final ClashLineup7v7 lineup;
  final ClashLineupsController controller;
  final ValueChanged<ClashPosition> onSlotTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent.withValues(alpha: 0.9),
            ),
          ),
        ),
        for (var i = 0; i < positions.length; i++) ...[
          ClashLineupSlotTile(
            position: positions[i],
            zoneAccent: accent,
            entry: controller.entryForCardId(lineup.cardIdFor(positions[i])),
            onTap: () => onSlotTap(positions[i]),
          ),
          if (i < positions.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}
