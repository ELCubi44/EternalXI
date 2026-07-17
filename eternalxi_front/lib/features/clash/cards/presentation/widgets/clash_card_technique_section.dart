import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_locked_technique_preview.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_epic_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_technique_upgrade_dialog.dart';
import 'package:flutter/material.dart';

/// Fila compacta de supertÃ©cnica con icono de tipo y nivel en esquina.
class ClashCardTechniqueSection extends StatelessWidget {
  const ClashCardTechniqueSection({
    required this.baseTechnique,
    required this.progress,
    required this.books,
    required this.isBusy,
    required this.onUseBook,
    super.key,
  });

  final ClashSuperTechnique baseTechnique;
  final ClashCardProgress? progress;
  final List<ClashTechniqueBookInventoryEntry> books;
  final bool isBusy;
  final ValueChanged<String> onUseBook;

  ClashTechniqueBookInventoryEntry? _pickBook() {
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: baseTechnique,
      progress: progress,
    );
    final compatible = books
        .where((e) => e.book.isCompatibleWith(resolved.type))
        .toList(growable: false);
    if (compatible.isEmpty) {
      return null;
    }

    compatible.sort((a, b) {
      final byReq = a.book.booksRequired.compareTo(b.book.booksRequired);
      if (byReq != 0) {
        return byReq;
      }
      return b.quantity.compareTo(a.quantity);
    });

    for (final entry in compatible) {
      if (entry.quantity >= entry.book.booksRequired) {
        return entry;
      }
    }
    return compatible.first;
  }

  Future<void> _openUpgrade(BuildContext context) async {
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: baseTechnique,
      progress: progress,
    );
    if (resolved.level.isMax) {
      return;
    }

    final book = _pickBook();
    if (book == null) {
      return;
    }

    final confirmed = await showClashTechniqueUpgradeDialog(
      context: context,
      techniqueName: resolved.name,
      currentLevel: resolved.level,
      bookEntry: book,
      isBusy: isBusy,
    );
    if (confirmed == true) {
      onUseBook(book.book.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: baseTechnique,
      progress: progress,
    );
    final atMax = resolved.level.isMax;
    final showLevelBadge = resolved.level != ClashTechniqueLevel.normal;
    final iconPath = ClashEpicAssets.techniqueTypeIcon(resolved.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: context.xiChipBackground.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                10,
                8,
                8,
                showLevelBadge ? 14 : 8,
              ),
              child: Row(
                children: [
                  Image.asset(
                    iconPath,
                    width: 28,
                    height: 28,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.sports_soccer_rounded,
                      size: 26,
                      color: ClashEpicAssets.techniqueTypeColor(resolved.type),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      resolved.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${resolved.effectivePower}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${resolved.ptCost} PT',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: context.xiTextSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed:
                        atMax || isBusy ? null : () => _openUpgrade(context),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 34),
                    ),
                    child: Text(l10n.clashActionUpgrade),
                  ),
                ],
              ),
            ),
          ),
          if (showLevelBadge)
            Positioned(
              left: -4,
              bottom: -4,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: XiColors.navyBlue,
                  border: Border.all(color: XiColors.classicGold, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Text(
                  resolved.level.displayLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: XiColors.classicGold,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// TÃ©cnica bloqueada (oscurecida) con pista de desbloqueo.
class ClashLockedTechniqueTile extends StatelessWidget {
  const ClashLockedTechniqueTile({required this.preview, super.key});

  final ClashLockedTechniquePreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final technique = preview.technique;
    final iconPath = ClashEpicAssets.techniqueTypeIcon(technique.type);
    final unlockText = preview.unlockLevel != null
        ? l10n.clashTechniqueUnlockByLevelOrRarity(
            preview.unlockLevel!,
            preview.unlockRarity.name.toUpperCase(),
          )
        : l10n.clashTechniqueUnlockByRarity(
            preview.unlockRarity.name.toUpperCase(),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(
            Colors.black54,
            BlendMode.darken,
          ),
          child: Stack(
            children: [
              Material(
                color: context.xiChipBackground.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                  child: Row(
                    children: [
                      Image.asset(
                        iconPath,
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.lock_rounded,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              technique.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              unlockText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: XiColors.classicGold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.lock_rounded,
                        size: 18,
                        color: XiColors.warmWhite.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

