import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_item_assets.dart';
import 'package:flutter/material.dart';

/// Modal opaco para confirmar mejora de supertùcnica (+1 nivel).
Future<bool?> showClashTechniqueUpgradeDialog({
  required BuildContext context,
  required String techniqueName,
  required ClashTechniqueLevel currentLevel,
  required ClashTechniqueBookInventoryEntry bookEntry,
  required bool isBusy,
}) {
  final nextLevel = currentLevel.advancedBy(1);
  final need = bookEntry.book.booksRequired;
  final have = bookEntry.quantity;
  final missing = (need - have).clamp(0, need);
  final canUpgrade = have >= need && !currentLevel.isMax;

  return showDialog<bool>(
    context: context,
    barrierDismissible: !isBusy,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) {
      final l10n = context.l10n;
      final theme = Theme.of(context);

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Material(
          color: context.xiBackground,
          elevation: 16,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.clashTechniqueUpgradeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  techniqueName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentLevel.displayLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      nextLevel.displayLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.clashTechniqueUpgradeRequirements,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.xiTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ClashTechniqueBookRequirementTile(
                  bookEntry: bookEntry,
                  need: need,
                  have: have,
                  missing: missing,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isBusy
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: (!canUpgrade || isBusy)
                            ? null
                            : () => Navigator.of(context).pop(true),
                        child: Text(l10n.clashActionUpgrade),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Fila tùpica: icono del objeto + cantidades a la derecha (necesitas / faltan).
class ClashTechniqueBookRequirementTile extends StatelessWidget {
  const ClashTechniqueBookRequirementTile({
    required this.bookEntry,
    required this.need,
    required this.have,
    required this.missing,
    this.compact = false,
    super.key,
  });

  final ClashTechniqueBookInventoryEntry bookEntry;
  final int need;
  final int have;
  final int missing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconPath = ClashItemAssets.techniqueBookIcon(bookEntry.book.id);
    final iconSize = compact ? 52.0 : 68.0;

    return Container(
      padding: EdgeInsets.all(compact ? 8 : 12),
      decoration: BoxDecoration(
        color: context.xiChipBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: XiColors.navyBlue,
                      border: Border.all(
                        color: XiColors.classicGold,
                        width: 2.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        iconPath,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: context.xiChipBackground,
                          child: Icon(
                            Icons.menu_book_rounded,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: XiColors.classicGold,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: XiColors.navyBlue, width: 1.5),
                    ),
                    child: Text(
                      'x$need',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: XiColors.navyBlue,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _QtyBlock(
                    value: '$need',
                    caption: context.l10n
                        .clashTechniqueUpgradeNeed(need)
                        .split(' ')
                        .first,
                    color: theme.colorScheme.primary,
                    compact: compact,
                  ),
                ),
                Expanded(
                  child: _QtyBlock(
                    // Solo el nùmero que falta (sin texto "Faltan ù").
                    value: '?$missing',
                    caption: '',
                    color: missing > 0
                        ? theme.colorScheme.error
                        : context.xiTextSecondary,
                    compact: compact,
                    emphasize: missing > 0,
                  ),
                ),
                Expanded(
                  child: _QtyBlock(
                    value: '$have',
                    caption: context.l10n.clashItemHave(have).split(' ').first,
                    color: XiColors.warmWhite.withValues(alpha: 0.9),
                    compact: compact,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBlock extends StatelessWidget {
  const _QtyBlock({
    required this.value,
    required this.caption,
    required this.color,
    required this.compact,
    this.emphasize = false,
  });

  final String value;
  final String caption;
  final Color color;
  final bool compact;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            fontSize: compact ? 18 : 22,
            height: 1,
          ),
        ),
        if (caption.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: emphasize ? color : context.xiTextSecondary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 9 : 10,
            ),
          ),
        ],
      ],
    );
  }
}
