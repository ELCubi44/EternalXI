import 'dart:math' as math;

import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/core/utils/league_asset_urls.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Tile compacto estilo roster (grid denso, rareza + nivel + posicion).
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
    final levelLabel =
        entry.isMaxLevel ? 'MAX' : 'lvl ${entry.displayLevel}';
    final bgPath = ClashEpicAssets.detailBackgroundForTeam(
      entry.team,
      rarity,
    );
    final isPremiumBorder =
        rarity == ClashRarity.lr || rarity == ClashRarity.xi;
    final borderWidth = rarity == ClashRarity.xi
        ? 2.4
        : rarity == ClashRarity.lr
            ? 2.0
            : 1.6;
    final borderColor = rarity == ClashRarity.xi
        ? XiColors.techCyan
        : rarity == ClashRarity.lr
            ? const Color(0xFFFFB020)
            : XiColors.classicGold.withValues(alpha: 0.85);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: rarityColor.withValues(
                  alpha: rarity == ClashRarity.xi ? 0.55 : 0.28,
                ),
                blurRadius: rarity == ClashRarity.xi ? 10 : 6,
                spreadRadius: rarity == ClashRarity.xi ? 0.6 : 0,
              ),
              if (rarity == ClashRarity.xi)
                BoxShadow(
                  color: XiColors.classicGold.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8.2),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: XiColors.navyBlue),
                Image.asset(
                  bgPath,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
                ColoredBox(color: Colors.black.withValues(alpha: 0.22)),
                if (photoUrl != null)
                  Opacity(
                    opacity: 0.88,
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => _InitialsFallback(
                        name: entry.name,
                        color: rarityColor,
                      ),
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
                      padding: const EdgeInsets.fromLTRB(3, 14, 3, 3),
                      child: Row(
                        children: [
                          Image.asset(
                            ClashEpicAssets.rarityIcon(rarity),
                            width: 22,
                            height: 22,
                            filterQuality: FilterQuality.medium,
                            errorBuilder: (_, __, ___) => Container(
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
                  top: 3,
                  right: 3,
                  child: Image.asset(
                    ClashEpicAssets.positionIcon(entry.card.position),
                    width: 20,
                    height: 20,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
                if (isPremiumBorder)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RaritySparkPainter(
                          color: rarity == ClashRarity.xi
                              ? XiColors.techCyan
                              : const Color(0xFFFFB020),
                          secondary: rarity == ClashRarity.xi
                              ? XiColors.classicGold
                              : rarityColor,
                          intensity: rarity == ClashRarity.xi ? 1.0 : 0.62,
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

class _RaritySparkPainter extends CustomPainter {
  const _RaritySparkPainter({
    required this.color,
    required this.secondary,
    required this.intensity,
  });

  final Color color;
  final Color secondary;
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final boltPaint = Paint()
      ..color = color.withValues(alpha: 0.92 * intensity)
      ..strokeWidth = intensity >= 0.9 ? 1.35 : 1.05
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final softPaint = Paint()
      ..color = secondary.withValues(alpha: 0.55 * intensity)
      ..strokeWidth = boltPaint.strokeWidth + 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4);

    final bolts = <List<Offset>>[
      [
        Offset(size.width * 0.08, size.height * 0.12),
        Offset(size.width * 0.16, size.height * 0.05),
        Offset(size.width * 0.14, size.height * 0.14),
        Offset(size.width * 0.22, size.height * 0.08),
      ],
      [
        Offset(size.width * 0.92, size.height * 0.14),
        Offset(size.width * 0.84, size.height * 0.06),
        Offset(size.width * 0.88, size.height * 0.16),
        Offset(size.width * 0.78, size.height * 0.10),
      ],
      [
        Offset(size.width * 0.10, size.height * 0.88),
        Offset(size.width * 0.18, size.height * 0.94),
        Offset(size.width * 0.16, size.height * 0.84),
        Offset(size.width * 0.24, size.height * 0.90),
      ],
      [
        Offset(size.width * 0.90, size.height * 0.86),
        Offset(size.width * 0.82, size.height * 0.94),
        Offset(size.width * 0.86, size.height * 0.82),
        Offset(size.width * 0.76, size.height * 0.90),
      ],
    ];

    if (intensity >= 0.9) {
      bolts.addAll([
        [
          Offset(size.width * 0.48, size.height * 0.03),
          Offset(size.width * 0.54, size.height * 0.09),
          Offset(size.width * 0.50, size.height * 0.12),
          Offset(size.width * 0.58, size.height * 0.05),
        ],
        [
          Offset(size.width * 0.46, size.height * 0.97),
          Offset(size.width * 0.54, size.height * 0.91),
          Offset(size.width * 0.50, size.height * 0.88),
          Offset(size.width * 0.60, size.height * 0.95),
        ],
      ]);
    }

    for (final points in bolts) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, softPaint);
      canvas.drawPath(path, boltPaint);
    }

    final sparkPaint = Paint()
      ..color = color.withValues(alpha: 0.85 * intensity)
      ..style = PaintingStyle.fill;
    final sparks = <Offset>[
      Offset(size.width * 0.06, size.height * 0.22),
      Offset(size.width * 0.94, size.height * 0.28),
      Offset(size.width * 0.08, size.height * 0.72),
      Offset(size.width * 0.93, size.height * 0.68),
    ];
    if (intensity >= 0.9) {
      sparks.addAll([
        Offset(size.width * 0.28, size.height * 0.05),
        Offset(size.width * 0.72, size.height * 0.06),
        Offset(size.width * 0.30, size.height * 0.95),
        Offset(size.width * 0.70, size.height * 0.94),
      ]);
    }
    for (final spark in sparks) {
      canvas.drawCircle(spark, 1.15 * intensity, sparkPaint);
      _drawMiniStar(canvas, spark, 2.6 * intensity, softPaint.color);
    }
  }

  void _drawMiniStar(Canvas canvas, Offset center, double radius, Color c) {
    final paint = Paint()
      ..color = c
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      center.translate(-radius, 0),
      center.translate(radius, 0),
      paint,
    );
    canvas.drawLine(
      center.translate(0, -radius),
      center.translate(0, radius),
      paint,
    );
    final d = radius * math.cos(math.pi / 4);
    canvas.drawLine(
      center.translate(-d, -d),
      center.translate(d, d),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RaritySparkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.secondary != secondary ||
        oldDelegate.intensity != intensity;
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
