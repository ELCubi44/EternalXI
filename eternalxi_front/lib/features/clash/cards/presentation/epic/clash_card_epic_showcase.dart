import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_table.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Presentacion epica de carta Clash (detalle o tile compacto).
class ClashCardEpicShowcase extends StatelessWidget {
  const ClashCardEpicShowcase({
    required this.entry,
    this.compact = false,
    this.detailHero = false,
    this.onLevelUpTap,
    this.height,
    super.key,
  });

  final ClashCardCatalogEntry entry;
  final bool compact;
  final bool detailHero;
  final VoidCallback? onLevelUpTap;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final resolvedHeight = height ??
        (compact
            ? 280.0
            : (MediaQuery.sizeOf(context).height * 0.68));

    final clampedHeight = this.height != null
        ? resolvedHeight
        : resolvedHeight.clamp(
            compact ? 240.0 : 380.0,
            compact ? 320.0 : 720.0,
          );

    if (compact) {
      return SizedBox(
        height: clampedHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _EpicBackground(entry: entry),
              _PortraitLayer(
                entry: entry,
                compact: true,
                detailHero: detailHero,
              ),
              _CompactFooter(entry: entry),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: clampedHeight,
      width: double.infinity,
      child: ClipRRect(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                fit: StackFit.expand,
                children: [
                  _EpicBackground(entry: entry),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.12),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                          stops: const [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  _PortraitLayer(
                    entry: entry,
                    compact: false,
                    detailHero: detailHero,
                  ),
                ],
              ),
            ),
            _StatsPanel(
              entry: entry,
              onLevelUpTap: onLevelUpTap,
            ),
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
  const _PortraitLayer({
    required this.entry,
    required this.compact,
    required this.detailHero,
  });

  final ClashCardCatalogEntry entry;
  final bool compact;
  final bool detailHero;

  @override
  Widget build(BuildContext context) {
    final rarity = entry.effectiveRarity;
    final safeTop = MediaQuery.paddingOf(context).top;
    final badgeRowHeight = compact
        ? 52.0
        : (detailHero ? 84.0 : 64.0);
    final top = compact
        ? 28.0
        : (detailHero ? safeTop + 54.0 : 36.0);
    final sideInset = compact ? 12.0 : 16.0;

    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        Positioned(
          top: top,
          left: sideInset,
          right: sideInset,
          height: badgeRowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _RarityFrameBadge(
                rarity: rarity,
                compact: compact,
                detailHero: detailHero,
              ),
              const Spacer(),
              _PwrBadge(
                power: entry.power,
                compact: compact,
                detailHero: detailHero,
              ),
            ],
          ),
        ),
        Positioned(
          top: top + badgeRowHeight + (compact ? 4.0 : 6.0),
          left: compact ? 20 : 24,
          right: compact ? 20 : 24,
          bottom: compact ? 56 : 0,
          child: ClipRect(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _PlayerPortrait(entry: entry, compact: compact),
            ),
          ),
        ),
      ],
    );
  }
}

class _RarityFrameBadge extends StatelessWidget {
  const _RarityFrameBadge({
    required this.rarity,
    required this.compact,
    this.detailHero = false,
  });

  final ClashRarity rarity;
  final bool compact;
  final bool detailHero;

  @override
  Widget build(BuildContext context) {
    final size = compact
        ? 44.0
        : (detailHero ? 76.0 : 56.0);

    final color = ClashRarityBadge.color(rarity);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            ClashEpicAssets.rarityBadgeFrame(rarity),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
          ),
          Text(
            ClashRarityBadge.label(rarity),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 10 : (detailHero ? 16 : 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PwrBadge extends StatelessWidget {
  const _PwrBadge({
    required this.power,
    required this.compact,
    this.detailHero = false,
  });

  final int power;
  final bool compact;
  final bool detailHero;

  @override
  Widget build(BuildContext context) {
    final size = compact
        ? 52.0
        : (detailHero ? 88.0 : 64.0);

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
                  fontSize: compact ? 11 : (detailHero ? 16 : 13),
                  height: 1,
                ),
              ),
              Text(
                'PWR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: XiColors.classicGold,
                  fontWeight: FontWeight.w800,
                  fontSize: compact ? 8 : (detailHero ? 11 : 9),
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
  const _PlayerPortrait({required this.entry, required this.compact});

  final ClashCardCatalogEntry entry;
  final bool compact;

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

    if (url == null) {
      return _InitialsFallback(name: entry.name);
    }

    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, __, ___) => _InitialsFallback(name: entry.name),
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
  const _StatsPanel({required this.entry, this.onLevelUpTap});

  final ClashCardCatalogEntry entry;
  final VoidCallback? onLevelUpTap;

  static const _statSegment = 100;

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

    return Container(
      height: 208,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        color: XiColors.navyBlue.withValues(alpha: 0.98),
        border: Border.all(
          color: XiColors.classicGold.withValues(alpha: 0.65),
          width: 1.5,
        ),
      ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
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
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.position.displayNameEs,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: XiColors.warmWhite.withValues(alpha: 0.72),
                          ),
                        ),
                        Text(
                          card.style.displayNameEs,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: XiColors.classicGold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 116,
                    child: Column(
                      children: [
                        _EpicStatRow(
                          kind: ClashEpicStatKind.par,
                          label: 'PAR',
                          value: stats.save,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.def,
                          label: 'DEF',
                          value: stats.defense,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.pas,
                          label: 'PAS',
                          value: stats.pass,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.reg,
                          label: 'REG',
                          value: stats.dribble,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.tir,
                          label: 'TIR',
                          value: stats.shot,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.pt,
                          label: 'PT',
                          value: stats.techniquePoints,
                          segment: _statSegment,
                        ),
                        _EpicStatRow(
                          kind: ClashEpicStatKind.res,
                          label: 'RES',
                          value: stats.stamina,
                          segment: _statSegment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    levelLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: XiColors.warmWhite,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: entry.isMaxLevel ? 1.0 : xpRatio,
                        minHeight: 7,
                        backgroundColor: Colors.black.withValues(alpha: 0.35),
                        color: XiColors.classicGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: XiColors.classicGold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: entry.isMaxLevel ? null : onLevelUpTap,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: XiColors.classicGold.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: entry.isMaxLevel
                              ? XiColors.warmWhite.withValues(alpha: 0.35)
                              : XiColors.classicGold,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
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
    required this.segment,
  });

  final ClashEpicStatKind kind;
  final String label;
  final int value;
  final int segment;

  @override
  Widget build(BuildContext context) {
    final color = ClashEpicAssets.statColor(kind);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
          Expanded(child: _LayeredStatBar(value: value, color: color, segment: segment)),
          const SizedBox(width: 4),
          SizedBox(
            width: 26,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: XiColors.warmWhite,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayeredStatBar extends StatelessWidget {
  const _LayeredStatBar({
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
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 5,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: Colors.black.withValues(alpha: 0.35)),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: baseFill.clamp(0.0, 1.0),
              child: ColoredBox(color: color),
            ),
            if (overflowFill > 0)
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: overflowFill.clamp(0.0, 1.0),
                child: ColoredBox(color: XiColors.classicGold),
              ),
          ],
        ),
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
