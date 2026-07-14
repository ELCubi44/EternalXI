import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Presentaciùn ùpica de carta Clash (detalle o tile compacto).
class ClashCardEpicShowcase extends StatelessWidget {
  const ClashCardEpicShowcase({
    required this.entry,
    this.compact = false,
    super.key,
  });

  final ClashCardCatalogEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final height = compact ? 280.0 : MediaQuery.sizeOf(context).height * 0.62;

    return SizedBox(
      height: height.clamp(compact ? 240.0 : 420.0, compact ? 320.0 : 680.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(compact ? 14 : 0),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _EpicBackground(entry: entry),
            if (!compact) ...[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                      stops: const [0, 0.45, 1],
                    ),
                  ),
                ),
              ),
            ],
            _PortraitLayer(entry: entry, compact: compact),
            if (!compact) _StatsPanel(entry: entry),
            if (compact) _CompactFooter(entry: entry),
          ],
        ),
      ),
    );
  }
}

class _EpicBackground extends StatelessWidget {
  const _EpicBackground({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final path = ClashEpicAssets.detailBackgroundForTeam(
      entry.team,
      entry.effectiveRarity,
    );
    final fallback = ClashRarityBadge.color(entry.effectiveRarity);

    return Image.asset(
      path,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              fallback.withValues(alpha: 0.35),
              XiColors.nightBlue,
            ],
          ),
        ),
      ),
    );
  }
}

class _PortraitLayer extends StatelessWidget {
  const _PortraitLayer({required this.entry, required this.compact});

  final ClashCardCatalogEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rarity = entry.effectiveRarity;
    final portraitHeight = compact ? 130.0 : 240.0;
    final top = compact ? 28.0 : 56.0;

    return Stack(
      children: [
        if (!compact)
          Positioned(
            top: top + 20,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                ClashEpicAssets.auraGlow(rarity),
                width: 260,
                height: 260,
                fit: BoxFit.contain,
                color: ClashRarityBadge.color(rarity).withValues(alpha: 0.85),
                colorBlendMode: BlendMode.srcATop,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        Positioned(
          top: top,
          left: compact ? 12 : 24,
          right: compact ? 12 : 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RarityFrameBadge(rarity: rarity, compact: compact),
              const Spacer(),
              _PwrBadge(power: entry.power, compact: compact),
            ],
          ),
        ),
        Positioned(
          top: top + (compact ? 36 : 48),
          left: compact ? 24 : 48,
          right: compact ? 24 : 48,
          height: portraitHeight,
          child: _PlayerPortrait(entry: entry),
        ),
      ],
    );
  }
}

class _RarityFrameBadge extends StatelessWidget {
  const _RarityFrameBadge({required this.rarity, required this.compact});

  final ClashRarity rarity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 44.0 : 56.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            ClashEpicAssets.rarityBadgeFrame(rarity),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
          Text(
            ClashRarityBadge.label(rarity),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: ClashRarityBadge.color(rarity),
              fontWeight: FontWeight.w900,
              fontSize: compact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _PwrBadge extends StatelessWidget {
  const _PwrBadge({required this.power, required this.compact});

  final int power;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 52.0 : 64.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            ClashEpicAssets.pwrBadge,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: XiColors.classicGold, width: 2),
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$power',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: XiColors.warmWhite,
                  fontWeight: FontWeight.w900,
                  fontSize: compact ? 11 : 13,
                  height: 1,
                ),
              ),
              Text(
                'PWR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: XiColors.classicGold,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 8 : 9,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlayerPortrait extends StatelessWidget {
  const _PlayerPortrait({required this.entry});

  final ClashCardCatalogEntry entry;

  String? get _photoUrl {
    final id = entry.playerId;
    if (id > 0) {
      return LeagueAssetUrls.resolvePlayerPhotoUrl(idJugador: id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _photoUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url == null
          ? _InitialsFallback(name: entry.name)
          : Image.network(
              url,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) =>
                  _InitialsFallback(name: entry.name),
            ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  const _InitialsFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : (parts.isEmpty ? '?' : parts.first[0].toUpperCase());

    return ColoredBox(
      color: XiColors.navyBlue.withValues(alpha: 0.65),
      child: Center(
        child: Text(
          initials,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: XiColors.warmWhite,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final stats = entry.displayStats;
    final card = entry.displayCard;
    final levelLabel = entry.isMaxLevel
        ? l10n.clashCardMaxLevel
        : '${entry.displayLevel} / ${entry.effectiveRarity.maxLevel}';
    final progress = entry.progress;
    final currentXp = progress?.currentExperience ?? 0;
    final needed =
        entry.xpToNextLevel ??
        ClashCardXpTable.xpToNextLevel(
          entry.displayLevel,
          entry.effectiveRarity,
        );
    final xpRatio = needed <= 0 ? 1.0 : (currentXp / needed).clamp(0.0, 1.0);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: 240,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              ClashEpicAssets.statsPanel,
              fit: BoxFit.fill,
              alignment: Alignment.bottomCenter,
              errorBuilder: (_, __, ___) => DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      XiColors.navyBlue.withValues(alpha: 0.92),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: XiColors.warmWhite,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${entry.team} ù ${card.position.displayNameEs}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: XiColors.warmWhite.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                            Text(
                              '${card.style.displayNameEs} ù $levelLabel',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: XiColors.classicGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 108,
                        child: Column(
                          children: [
                            _EpicStatRow(
                              kind: ClashEpicStatKind.par,
                              label: 'PAR',
                              value: stats.save,
                            ),
                            _EpicStatRow(
                              kind: ClashEpicStatKind.def,
                              label: 'DEF',
                              value: stats.defense,
                            ),
                            _EpicStatRow(
                              kind: ClashEpicStatKind.pas,
                              label: 'PAS',
                              value: stats.pass,
                            ),
                            _EpicStatRow(
                              kind: ClashEpicStatKind.reg,
                              label: 'REG',
                              value: stats.dribble,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _EpicStatChip(
                              kind: ClashEpicStatKind.tir,
                              label: 'TIR',
                              value: stats.shot,
                            ),
                            _EpicStatChip(
                              kind: ClashEpicStatKind.pt,
                              label: 'PT',
                              value: stats.techniquePoints,
                            ),
                            _EpicStatChip(
                              kind: ClashEpicStatKind.res,
                              label: 'RES',
                              value: stats.stamina,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (!entry.isMaxLevel) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: xpRatio,
                        minHeight: 6,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        color: XiColors.classicGold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactFooter extends StatelessWidget {
  const _CompactFooter({required this.entry});

  final ClashCardCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final stats = entry.displayStats;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 28, 10, 8),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: XiColors.warmWhite,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  l10n.clashCardPowerValue(entry.power),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: XiColors.classicGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _EpicStatChip(
                  kind: ClashEpicStatKind.tir,
                  label: 'TIR',
                  value: stats.shot,
                  dense: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EpicStatRow extends StatelessWidget {
  const _EpicStatRow({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: (value / 150).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: Colors.black.withValues(alpha: 0.35),
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 28,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: XiColors.warmWhite,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpicStatChip extends StatelessWidget {
  const _EpicStatChip({
    required this.kind,
    required this.label,
    required this.value,
    this.dense = false,
  });

  final ClashEpicStatKind kind;
  final String label;
  final int value;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final color = ClashEpicAssets.statColor(kind);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 8,
        vertical: dense ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: dense ? 10 : 11,
        ),
      ),
    );
  }
}
