import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Panel de estadísticas del detalle de carta (Fase 36).
class ClashCardStatsPanel extends StatelessWidget {
  const ClashCardStatsPanel({required this.entry, super.key});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stats = entry.displayStats;

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashCardStats,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.clashCardBonusIncluded,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ClashCardDetailMetaRow(label: l10n.clashCardTeam, value: entry.team),
          ClashCardDetailMetaRow(
            label: l10n.clashCardLevel,
            value: '${entry.displayLevel} / ${entry.effectiveRarity.maxLevel}',
          ),
          const Divider(height: 20),
          ClashCardDetailStatRow(label: l10n.clashStatSave, value: stats.save),
          ClashCardDetailStatRow(
            label: l10n.clashStatDefense,
            value: stats.defense,
          ),
          ClashCardDetailStatRow(label: l10n.clashStatPass, value: stats.pass),
          ClashCardDetailStatRow(
            label: l10n.clashStatDribble,
            value: stats.dribble,
          ),
          ClashCardDetailStatRow(label: l10n.clashStatShot, value: stats.shot),
          ClashCardDetailStatRow(
            label: l10n.clashStatPt,
            value: stats.techniquePoints,
          ),
          ClashCardDetailStatRow(
            label: l10n.clashStatStamina,
            value: stats.stamina,
          ),
        ],
      ),
    );
  }
}
