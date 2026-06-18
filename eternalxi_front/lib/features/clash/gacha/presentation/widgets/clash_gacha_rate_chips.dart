import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:flutter/material.dart';

/// Bloque compacto de probabilidades de gacha (Fase 38).
class ClashGachaRateChips extends StatelessWidget {
  const ClashGachaRateChips({required this.rates, super.key});

  final ClashGachaRarityRates rates;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final showUnavailable = rates.lrPercent == 0 && rates.xiPercent == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.clashSummonRates,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _RateChip(rarity: ClashRarity.n, value: rates.nPercent),
            _RateChip(rarity: ClashRarity.r, value: rates.rPercent),
            _RateChip(rarity: ClashRarity.sr, value: rates.srPercent),
            if (rates.lrPercent > 0)
              _RateChip(rarity: ClashRarity.lr, value: rates.lrPercent),
            if (rates.xiPercent > 0)
              _RateChip(rarity: ClashRarity.xi, value: rates.xiPercent),
          ],
        ),
        if (showUnavailable) ...[
          const SizedBox(height: 8),
          Text(
            l10n.clashGachaLrXiUnavailable,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.clashGachaMultiGuarantee,
          style: theme.textTheme.bodySmall?.copyWith(
            color: context.xiTextSecondary,
          ),
        ),
      ],
    );
  }
}

class _RateChip extends StatelessWidget {
  const _RateChip({required this.rarity, required this.value});

  final ClashRarity rarity;
  final int value;

  @override
  Widget build(BuildContext context) {
    final accent = ClashRarityBadge.color(rarity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${ClashRarityBadge.label(rarity)} $value%',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}
