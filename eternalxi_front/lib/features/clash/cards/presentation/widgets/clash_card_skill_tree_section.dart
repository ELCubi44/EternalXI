import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_definition.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_node.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_skill_tree_service.dart';
import 'package:eternal_xi/features/clash/cards/presentation/widgets/clash_card_detail_shared.dart';
import 'package:flutter/material.dart';

/// Sección de árbol de habilidades en detalle de carta (Fase 36).
class ClashCardSkillTreeSection extends StatelessWidget {
  const ClashCardSkillTreeSection({
    required this.entry,
    required this.isBusy,
    required this.onUnlock,
    super.key,
  });

  final ClashCardCatalogEntry entry;
  final bool isBusy;
  final ValueChanged<String> onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final card = entry.card;
    final progress = entry.progress;
    final eligible = entry.hasSkillTree;

    return ClashCardDetailSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_tree_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.clashSkillTreeTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!eligible || progress == null) ...[
            Text(
              l10n.clashSkillTreeLockedRarity,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.xiTextSecondary,
              ),
            ),
          ] else ...[
            Text(l10n.clashSkillTreeDuplicates(progress.duplicateCopies)),
            const SizedBox(height: 6),
            Text(
              l10n.clashSkillTreeProgress(
                progress.unlockedDuplicateNodes,
                ClashSkillTreeDefinition.nodeCount,
              ),
            ),
            const SizedBox(height: 14),
            for (final node in ClashSkillTreeDefinition.nodesFor(card.position))
              _SkillTreeNodeRow(
                node: node,
                progress: progress,
                card: card,
                isBusy: isBusy,
                onUnlock: onUnlock,
              ),
          ],
        ],
      ),
    );
  }
}

enum _SkillTreeNodeVisualState { locked, available, unlocked }

class _SkillTreeNodeRow extends StatelessWidget {
  const _SkillTreeNodeRow({
    required this.node,
    required this.progress,
    required this.card,
    required this.isBusy,
    required this.onUnlock,
  });

  final ClashSkillTreeNode node;
  final ClashCardProgress progress;
  final ClashCard card;
  final bool isBusy;
  final ValueChanged<String> onUnlock;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final state = _resolveState();

    final statusLabel = switch (state) {
      _SkillTreeNodeVisualState.unlocked => l10n.clashSkillTreeNodeUnlocked,
      _SkillTreeNodeVisualState.available => l10n.clashSkillTreeNodeAvailable,
      _SkillTreeNodeVisualState.locked => l10n.clashSkillTreeNodeLocked,
    };

    final statusColor = switch (state) {
      _SkillTreeNodeVisualState.unlocked => theme.colorScheme.primary,
      _SkillTreeNodeVisualState.available => theme.colorScheme.tertiary,
      _SkillTreeNodeVisualState.locked => context.xiTextSecondary,
    };

    final canUnlock = state == _SkillTreeNodeVisualState.available && !isBusy;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  node.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                statusLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            node.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: context.xiTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            node.boostLabel,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (canUnlock) ...[
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => onUnlock(node.id),
              child: Text(l10n.clashSkillTreeUnlock),
            ),
          ],
        ],
      ),
    );
  }

  _SkillTreeNodeVisualState _resolveState() {
    if (ClashSkillTreeService.isNodeUnlocked(progress, node.id)) {
      return _SkillTreeNodeVisualState.unlocked;
    }
    if (ClashSkillTreeService.canUnlockNode(
      card: card,
      progress: progress,
      node: node,
    )) {
      return _SkillTreeNodeVisualState.available;
    }
    return _SkillTreeNodeVisualState.locked;
  }
}
