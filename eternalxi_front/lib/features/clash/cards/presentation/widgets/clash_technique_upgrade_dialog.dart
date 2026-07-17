import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_item_assets.dart';
import 'package:flutter/material.dart';

/// Modal para confirmar mejora de supertùcnica (+1 nivel gastando N libros).
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
    builder: (context) {
      final l10n = context.l10n;
      final theme = Theme.of(context);
      final iconPath = ClashItemAssets.techniqueBookIcon(bookEntry.book.id);

      return AlertDialog(
        backgroundColor: context.xiBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.clashTechniqueUpgradeTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              techniqueName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${currentLevel.displayLabel} ? ${nextLevel.displayLabel}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: XiColors.classicGold,
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: XiColors.classicGold.withValues(alpha: 0.28),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: XiColors.navyBlue,
                  child: Image.asset(
                    iconPath,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => SizedBox(
                      width: 120,
                      height: 120,
                      child: Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.clashTechniqueUpgradeNeed(need),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.clashItemHave(have),
              style: theme.textTheme.bodySmall,
            ),
            Text(
              l10n.clashItemMissing(missing),
              style: theme.textTheme.bodySmall?.copyWith(
                color: missing > 0
                    ? theme.colorScheme.error
                    : context.xiTextSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: isBusy ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: (!canUpgrade || isBusy)
                ? null
                : () => Navigator.of(context).pop(true),
            child: Text(l10n.clashActionUpgrade),
          ),
        ],
      );
    },
  );
}
