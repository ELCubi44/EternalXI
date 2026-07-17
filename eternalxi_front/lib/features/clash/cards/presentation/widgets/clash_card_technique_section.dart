import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/presentation/epic/clash_item_assets.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Lista simple de supertécnicas + mejorar con iconos de objeto.
class ClashCardTechniqueSection extends StatefulWidget {
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

  @override
  State<ClashCardTechniqueSection> createState() =>
      _ClashCardTechniqueSectionState();
}

class _ClashCardTechniqueSectionState extends State<ClashCardTechniqueSection> {
  bool _upgradeOpen = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: widget.baseTechnique,
      progress: widget.progress,
    );
    final atMax = resolved.level.isMax;
    final compatibleBooks = widget.books
        .where((e) => e.book.isCompatibleWith(resolved.type))
        .toList(growable: false);

    return ClashCardDetailSectionCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            resolved.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ClashCardDetailMetaRow(
            label: l10n.clashTechniqueLevel,
            value: resolved.level.displayLabel,
          ),
          ClashCardDetailMetaRow(
            label: l10n.clashTechniquePower,
            value: '${resolved.effectivePower}',
          ),
          ClashCardDetailMetaRow(
            label: l10n.clashTechniquePtCost,
            value: '${resolved.ptCost}',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.tonal(
              onPressed: atMax
                  ? null
                  : () => setState(() => _upgradeOpen = !_upgradeOpen),
              child: Text(
                _upgradeOpen ? l10n.clashBack : l10n.clashActionUpgrade,
              ),
            ),
          ),
          if (atMax) ...[
            const SizedBox(height: 6),
            Text(
              l10n.clashCardMaxLevel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          if (_upgradeOpen && !atMax) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final item in compatibleBooks)
                  _TechniqueBookIconTile(
                    entry: item,
                    disabled: item.quantity <= 0 || widget.isBusy,
                    onUse: () => widget.onUseBook(item.book.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TechniqueBookIconTile extends StatelessWidget {
  const _TechniqueBookIconTile({
    required this.entry,
    required this.disabled,
    required this.onUse,
  });

  final ClashTechniqueBookInventoryEntry entry;
  final bool disabled;
  final VoidCallback onUse;

  static const _need = 1;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final have = entry.quantity;
    final missing = (_need - have).clamp(0, _need);
    final iconPath = ClashItemAssets.techniqueBookIcon(entry.book.id);

    return Material(
      color: context.xiChipBackground.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: disabled ? null : onUse,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 108,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.xiDivider),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  iconPath,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: context.xiChipBackground,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.clashTechniqueBookEffect(entry.book.levelUpSteps),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.clashItemHave(have),
                style: theme.textTheme.labelSmall,
              ),
              Text(
                l10n.clashItemMissing(missing),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: missing > 0
                      ? theme.colorScheme.error
                      : context.xiTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
