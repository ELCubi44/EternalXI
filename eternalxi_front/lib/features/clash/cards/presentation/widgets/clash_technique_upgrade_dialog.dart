import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_item_assets.dart';
import 'package:flutter/material.dart';

/// Modal para confirmar mejora de supertécnica (+1 nivel).
/// Solo icono del objeto + fracción tienes/necesitas y Cancelar/Mejorar.
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
  final canUpgrade = have >= need && !currentLevel.isMax;

  return showDialog<bool>(
    context: context,
    barrierDismissible: !isBusy,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    builder: (context) {
      final l10n = context.l10n;
      final theme = Theme.of(context);
      final iconPath = ClashItemAssets.techniqueBookIcon(bookEntry.book.id);

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
        child: Material(
          color: context.xiBackground,
          elevation: 16,
          borderRadius: BorderRadius.circular(22),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.clashTechniqueUpgradeTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  techniqueName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentLevel == ClashTechniqueLevel.normal
                          ? '—'
                          : currentLevel.displayLabel,
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
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
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
                    const SizedBox(width: 16),
                    Text(
                      '$have/$need',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: canUpgrade
                            ? theme.colorScheme.primary
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

