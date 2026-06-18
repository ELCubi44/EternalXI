import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Sección de supertécnica en detalle de carta (Fase 36).
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

  static String typeLabel(ClashTechniqueType type) => switch (type) {
    ClashTechniqueType.save => 'Parada',
    ClashTechniqueType.defense => 'Defensa',
    ClashTechniqueType.dribble => 'Regate',
    ClashTechniqueType.shot => 'Tiro',
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolved = ClashTechniqueProgressResolver.withResolvedLevel(
      technique: baseTechnique,
      progress: progress,
    );
    final atMax = resolved.level.isMax;

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flash_on_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashTechniqueSection,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  typeLabel(resolved.type),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            resolved.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            resolved.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ClashCardDetailMetaRow(
            label: l10n.clashCardStyle,
            value: resolved.style.displayNameEs,
          ),
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
          const SizedBox(height: 14),
          Text(
            l10n.clashTechniqueUpgradeTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (atMax) ...[
            const SizedBox(height: 8),
            Text(
              l10n.clashCardMaxLevel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          for (final item in books) ...[
            _TechniqueBookRow(
              entry: item,
              disabled: atMax || item.quantity <= 0 || isBusy,
              onUse: () => onUseBook(item.book.id),
            ),
            if (item != books.last) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _TechniqueBookRow extends StatelessWidget {
  const _TechniqueBookRow({
    required this.entry,
    required this.disabled,
    required this.onUse,
  });

  final ClashTechniqueBookInventoryEntry entry;
  final bool disabled;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final book = entry.book;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.xiChipBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  book.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                l10n.clashTechniqueBookEffect(book.levelUpSteps),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            book.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: context.xiTextSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.clashExpMaterialQuantity(entry.quantity),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              FilledButton.tonal(
                onPressed: disabled ? null : onUse,
                child: Text(l10n.clashTechniqueBookUse),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
