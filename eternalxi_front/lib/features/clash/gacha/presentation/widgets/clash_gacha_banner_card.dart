import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_banner.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:flutter/material.dart';

class ClashGachaBannerCard extends StatelessWidget {
  const ClashGachaBannerCard({
    required this.banner,
    required this.rates,
    super.key,
  });

  final ClashGachaBanner banner;
  final ClashGachaRarityRates rates;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  banner.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(banner.description),
        ],
      ),
    );
  }
}
