import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Panel de estadísticas del detalle (barras iguales que en la carta).
class ClashCardStatsPanel extends StatelessWidget {
  const ClashCardStatsPanel({required this.entry, super.key});

  final ClashCardCatalogEntry entry;

  static const _segment = 100;

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
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.par,
            label: 'PAR',
            value: stats.save,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.def,
            label: 'DEF',
            value: stats.defense,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.pas,
            label: 'PAS',
            value: stats.pass,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.reg,
            label: 'REG',
            value: stats.dribble,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.tir,
            label: 'TIR',
            value: stats.shot,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.pt,
            label: 'PT',
            value: stats.techniquePoints,
          ),
          _DetailEpicStatRow(
            kind: ClashEpicStatKind.res,
            label: 'RES',
            value: stats.stamina,
          ),
        ],
      ),
    );
  }
}

class _DetailEpicStatRow extends StatelessWidget {
  const _DetailEpicStatRow({
    required this.kind,
    required this.label,
    required this.value,
  });

  final ClashEpicStatKind kind;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final color = ClashEpicAssets.statColor(kind);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: _DetailLayeredStatBar(
              value: value,
              color: color,
              segment: ClashCardStatsPanel._segment,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailLayeredStatBar extends StatelessWidget {
  const _DetailLayeredStatBar({
    required this.value,
    required this.color,
    required this.segment,
  });

  final int value;
  final Color color;
  final int segment;

  @override
  Widget build(BuildContext context) {
    final safeSegment = segment <= 0 ? 100 : segment;
    final baseFill = (value.clamp(0, safeSegment)) / safeSegment;
    final overflowFill = value > safeSegment
        ? ((value - safeSegment).clamp(0, safeSegment)) / safeSegment
        : 0.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: context.xiChipBackground.withValues(alpha: 0.85),
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: baseFill.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
            if (overflowFill > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: overflowFill.clamp(0.0, 1.0),
                child: const ColoredBox(color: XiColors.classicGold),
              ),
          ],
        ),
      ),
    );
  }
}
