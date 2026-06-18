import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_portrait.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Cabecera del detalle de carta Clash (Fase 36).
class ClashCardDetailHeader extends StatelessWidget {
  const ClashCardDetailHeader({required this.entry, super.key});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final card = entry.displayCard;
    final levelLabel = entry.isMaxLevel
        ? l10n.clashCardMaxLevel
        : l10n.clashCardLevelShort(entry.displayLevel);

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClashCardPortrait(
            name: entry.name,
            imagePath: card.basicPortraitPath,
            height: 220,
            borderRadius: 18,
            rarity: entry.effectiveRarity,
            position: card.position,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  entry.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              ClashRarityBadge(rarity: entry.effectiveRarity),
            ],
          ),
          if (entry.isEvolved) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(l10n.clashCardEvolved),
                visualDensity: VisualDensity.compact,
                avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.sports_soccer_rounded,
                label: card.position.displayNameEs,
              ),
              _InfoChip(
                icon: Icons.bolt_rounded,
                label: card.style.displayNameEs,
              ),
              _InfoChip(
                icon: Icons.trending_up_rounded,
                label: l10n.clashCardPowerValue(entry.power),
              ),
              _InfoChip(icon: Icons.star_rounded, label: levelLabel),
            ],
          ),
          if (!entry.isMaxLevel) ...[
            const SizedBox(height: 12),
            _XpBar(entry: entry),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              l10n.clashCardMaxLevel,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.xiTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: context.xiChipBackground,
    );
  }
}

class _XpBar extends StatelessWidget {
  const _XpBar({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final progress = entry.progress;
    final currentXp = progress?.currentExperience ?? 0;
    final needed =
        entry.xpToNextLevel ??
        ClashCardXpTable.xpToNextLevel(
          entry.displayLevel,
          entry.effectiveRarity,
        );
    final ratio = needed <= 0 ? 0.0 : (currentXp / needed).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.clashCardXpTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: context.xiChipBackground,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.clashCardXpProgress(currentXp, needed),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
      ],
    );
  }
}
