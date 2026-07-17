import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tile compacto estilo roster (grid denso, rareza + nivel).
class ClashCardTile extends StatelessWidget {
  const ClashCardTile({required this.entry, this.onTap, super.key});

  final ClashCardCatalogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rarity = entry.effectiveRarity;
    final rarityColor = ClashRarityBadge.color(rarity);
    final photoUrl = LeagueAssetUrls.resolvePlayerPhotoUrl(
      idJugador: entry.playerId,
    );
    final levelLabel = entry.isMaxLevel
        ? 'MAX'
        : 'NV ${entry.displayLevel}';
    final pos = entry.card.position.displayNameEs;
    final posShort = pos.isEmpty ? '?' : pos.characters.first.toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: XiColors.classicGold.withValues(alpha: 0.85),
              width: 1.6,
            ),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.22),
                blurRadius: 6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.4),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: XiColors.navyBlue),
                if (photoUrl != null)
                  Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, __, ___) => _InitialsFallback(
                      name: entry.name,
                      color: rarityColor,
                    ),
                  )
                else
                  _InitialsFallback(name: entry.name, color: rarityColor),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.82),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: rarityColor.withValues(alpha: 0.9),
                              ),
                            ),
                            child: Text(
                              ClashRarityBadge.label(rarity),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: rarityColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 9,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            levelLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: XiColors.classicGold,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      posShort,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: XiColors.warmWhite,
                        fontWeight: FontWeight.w800,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ),
                if (entry.hasDuplicateCopies)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '+${entry.duplicateCopies}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: XiColors.warmWhite,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w.isEmpty ? '' : w[0])
            .join()
            .toUpperCase();

    return ColoredBox(
      color: color.withValues(alpha: 0.25),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: XiColors.warmWhite,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}
