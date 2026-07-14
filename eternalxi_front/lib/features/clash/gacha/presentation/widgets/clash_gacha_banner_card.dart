import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/gacha/presentation/widgets/clash_gacha_rate_chips.dart';
import 'package:flutter/material.dart';

class ClashGachaBannerCard extends StatelessWidget {
  const ClashGachaBannerCard({
    required this.banner,
    required this.rates,
    this.pityState,
    this.dailyAvailable = true,
    super.key,
  });

  final ClashGachaBanner banner;
  final ClashGachaRarityRates rates;
  final ClashGachaPityState? pityState;
  final bool dailyAvailable;

  bool get _useEpicArt =>
      banner.teamFilter == 'Eternal XI' ||
      banner.description.toLowerCase().contains('eternal xi');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pityMax =
        pityState?.threshold ?? ClashGachaPityState.defaultThreshold;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: XiColors.classicGold.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_useEpicArt)
                    Image.asset(
                      ClashEpicAssets.gachaBannerEternalXi,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                      errorBuilder: (_, __, ___) => DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              XiColors.nightBlue,
                              theme.colorScheme.primary.withValues(
                                alpha: 0.35,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.2),
                            context.xiCardSurface,
                          ],
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.78),
                          Colors.black.withValues(alpha: 0.35),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: XiColors.warmWhite,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          banner.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: XiColors.warmWhite.withValues(alpha: 0.82),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _CostChip(
                        label: l10n.clashGachaChipSingle(banner.singleCost),
                        icon: Icons.looks_one_rounded,
                      ),
                      _CostChip(
                        label: l10n.clashGachaChipMulti(banner.multiCost),
                        icon: Icons.filter_9_plus_rounded,
                      ),
                      if (banner.dailyDiscountAvailable)
                        _CostChip(
                          label: l10n.clashGachaChipDaily(
                            banner.dailyDiscountCost,
                          ),
                          icon: Icons.today_rounded,
                          highlight: dailyAvailable,
                        ),
                      _CostChip(
                        label: l10n.clashGachaChipPity(pityMax),
                        icon: Icons.favorite_rounded,
                      ),
                      _CostChip(
                        label: 'SR+',
                        icon: Icons.verified_rounded,
                        subtitle: l10n.clashGachaMultiGuarantee,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClashGachaRateChips(rates: rates),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostChip extends StatelessWidget {
  const _CostChip({
    required this.label,
    required this.icon,
    this.subtitle,
    this.highlight = false,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = highlight
        ? theme.colorScheme.primary
        : context.xiTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : context.xiChipBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? theme.colorScheme.primary.withValues(alpha: 0.4)
              : context.xiDivider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: highlight ? theme.colorScheme.primary : null,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: context.xiTextSecondary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
