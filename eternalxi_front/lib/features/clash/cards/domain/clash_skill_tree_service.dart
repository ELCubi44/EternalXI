import 'clash_card.dart';
import 'clash_card_evolution_resolver.dart';
import 'clash_card_progress.dart';
import 'clash_rarity.dart';
import 'clash_skill_tree_definition.dart';
import 'clash_skill_tree_node.dart';
import 'clash_skill_tree_unlock_result.dart';

class ClashSkillTreeService {
  const ClashSkillTreeService._();

  static bool rarityEligible(ClashRarity rarity) => rarity.hasDuplicateTree;

  static ClashSkillTreeNode? nextUnlockableNode({
    required ClashCard card,
    required ClashCardProgress progress,
  }) {
    final nodes = ClashSkillTreeDefinition.nodesFor(card.position);
    for (final node in nodes) {
      if (!progress.unlockedSkillNodeIds.contains(node.id)) {
        return node;
      }
    }
    return null;
  }

  static bool isNodeUnlocked(ClashCardProgress progress, String nodeId) {
    return progress.unlockedSkillNodeIds.contains(nodeId);
  }

  static bool canUnlockNode({
    required ClashCard card,
    required ClashCardProgress progress,
    required ClashSkillTreeNode node,
  }) {
    final rarity = ClashCardEvolutionResolver.effectiveRarity(card, progress);
    if (!rarityEligible(rarity)) {
      return false;
    }
    if (progress.duplicateCopies <= 0) {
      return false;
    }
    if (progress.unlockedSkillNodeIds.contains(node.id)) {
      return false;
    }
    if (node.order > 1) {
      final previousId = 'skill-${node.order - 1}';
      if (!progress.unlockedSkillNodeIds.contains(previousId)) {
        return false;
      }
    }
    return true;
  }

  static ClashSkillTreeUnlockResult previewUnlock({
    required String cardId,
    required ClashCard card,
    required ClashCardProgress progress,
    required String nodeId,
  }) {
    final rarity = ClashCardEvolutionResolver.effectiveRarity(card, progress);
    if (!rarityEligible(rarity)) {
      return _failed(
        cardId: cardId,
        nodeId: nodeId,
        progress: progress,
        error: ClashSkillTreeUnlockError.rarityNotEligible,
      );
    }

    final node = ClashSkillTreeDefinition.findNode(card.position, nodeId);
    if (node == null) {
      return _failed(
        cardId: cardId,
        nodeId: nodeId,
        progress: progress,
        error: ClashSkillTreeUnlockError.nodeNotFound,
      );
    }

    if (progress.isTreeMaximized) {
      return _failed(
        cardId: cardId,
        nodeId: nodeId,
        progress: progress,
        error: ClashSkillTreeUnlockError.treeMaximized,
      );
    }

    if (progress.unlockedSkillNodeIds.contains(nodeId)) {
      return _failed(
        cardId: cardId,
        nodeId: nodeId,
        progress: progress,
        error: ClashSkillTreeUnlockError.nodeAlreadyUnlocked,
      );
    }

    if (progress.duplicateCopies <= 0) {
      return _failed(
        cardId: cardId,
        nodeId: nodeId,
        progress: progress,
        error: ClashSkillTreeUnlockError.noDuplicates,
      );
    }

    if (node.order > 1) {
      final previousId = 'skill-${node.order - 1}';
      if (!progress.unlockedSkillNodeIds.contains(previousId)) {
        return _failed(
          cardId: cardId,
          nodeId: nodeId,
          progress: progress,
          error: ClashSkillTreeUnlockError.previousNodeLocked,
        );
      }
    }

    return ClashSkillTreeUnlockResult(
      cardId: cardId,
      nodeId: nodeId,
      duplicateConsumed: true,
      remainingDuplicates: progress.duplicateCopies - 1,
      unlocked: true,
      boostLabel: node.boostLabel,
    );
  }

  static ClashCardProgress progressAfterUnlock({
    required ClashCardProgress progress,
    required String nodeId,
  }) {
    return progress.copyWith(
      duplicateCopies: progress.duplicateCopies - 1,
      unlockedSkillNodeIds: {...progress.unlockedSkillNodeIds, nodeId},
    );
  }

  static ClashSkillTreeUnlockResult _failed({
    required String cardId,
    required String nodeId,
    required ClashCardProgress progress,
    required ClashSkillTreeUnlockError error,
  }) {
    return ClashSkillTreeUnlockResult(
      cardId: cardId,
      nodeId: nodeId,
      duplicateConsumed: false,
      remainingDuplicates: progress.duplicateCopies,
      unlocked: false,
      error: error,
    );
  }
}
