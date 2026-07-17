import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/app_colors.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_item_assets.dart';
import 'package:flutter/material.dart';

/// Modal opaco para confirmar mejora de supertécnica (+1 nivel).
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
      final iconPath = ClashItemAssets.techniqueBookIcon(bookEntry.book.id);

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
                const SizedBox(height: 12),
                Text(
                  techniqueName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${currentLevel.displayLabel}  ?  ${nextLevel.displayLabel}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.clashTechniqueUpgradeRequirements,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.xiTextSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 128,
                    height: 128,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: XiColors.navyBlue,
                      border: Border.all(
                        color: XiColors.classicGold,
                        width: 2.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: XiColors.classicGold.withValues(alpha: 0.3),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(
                            iconPath,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: context.xiChipBackground,
                              child: Icon(
                                Icons.menu_book_rounded,
                                size: 48,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.72),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: XiColors.classicGold.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              child: Text(
                                'x$need',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: XiColors.classicGold,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _RequirementRow(
                  label: l10n.clashTechniqueUpgradeNeed(need),
                  emphasize: true,
                ),
                _RequirementRow(label: l10n.clashItemHave(have)),
                _RequirementRow(
                  label: l10n.clashItemMissing(missing),
                  danger: missing > 0,
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

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.label,
    this.emphasize = false,
    this.danger = false,
  });

  final String label;
  final bool emphasize;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = danger
        ? theme.colorScheme.error
        : (emphasize
            ? theme.colorScheme.primary
            : context.xiTextPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: emphasize || danger ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
