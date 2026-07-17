import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_book_inventory_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_progress_resolver.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_technique_upgrade_dialog.dart';
import 'package:flutter/material.dart';

/// Lista simple de supertécnicas; Mejorar abre modal de confirmación.
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
      final byReq =
          a.book.booksRequired.compareTo(b.book.booksRequired);
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
            child: FilledButton(
              onPressed: atMax || isBusy ? null : () => _openUpgrade(context),
              child: Text(l10n.clashActionUpgrade),
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
        ],
      ),
    );
  }
}
