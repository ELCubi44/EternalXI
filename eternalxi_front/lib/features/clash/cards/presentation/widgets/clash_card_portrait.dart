import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_rarity_badge.dart';
import 'package:flutter/material.dart';

/// Retrato básico o placeholder con iniciales cuando no hay imagen real.
class ClashCardPortrait extends StatelessWidget {
  const ClashCardPortrait({
    required this.name,
    required this.imagePath,
    this.height,
    this.borderRadius = 14,
    this.rarity,
    this.position,
    super.key,
  });

  final String name;
  final String imagePath;
  final double? height;
  final double borderRadius;
  final ClashRarity? rarity;
  final ClashPosition? position;

  static bool isPlaceholder(String path) {
    final normalized = path.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized == 'placeholder' ||
        normalized.startsWith('clash://placeholder');
  }

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  Color get _accentColor {
    if (rarity != null) {
      return ClashRarityBadge.color(rarity!);
    }
    return XiColors.royalBlue;
  }

  @override
  Widget build(BuildContext context) {
    final usePlaceholder = isPlaceholder(imagePath);
    final accent = _accentColor;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.22),
              context.xiCardElevated,
              XiColors.navyBlue.withValues(
                alpha: context.isXiDark ? 0.55 : 0.1,
              ),
            ],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!usePlaceholder)
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _PlaceholderContent(
                      initials: _initials,
                      position: position,
                      accent: accent,
                    ),
              )
            else
              _PlaceholderContent(
                initials: _initials,
                position: position,
                accent: accent,
              ),
            if (rarity != null)
              Positioned(
                top: 8,
                right: 8,
                child: ClashRarityBadge(rarity: rarity!),
              ),
            if (position != null)
              Positioned(
                left: 8,
                bottom: 8,
                child: _PositionTag(label: position!.displayNameEs),
              ),
          ],
        ),
      ),
    );
  }
}

class _PositionTag extends StatelessWidget {
  const _PositionTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlaceholderContent extends StatelessWidget {
  const _PlaceholderContent({
    required this.initials,
    required this.accent,
    this.position,
  });

  final String initials;
  final Color accent;
  final ClashPosition? position;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.18),
                border: Border.all(color: accent.withValues(alpha: 0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.clashCardPortraitPlaceholder,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.xiTextSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
