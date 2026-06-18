enum ClashSkillTreeUnlockError {
  cardNotOwned,
  cardNotFound,
  rarityNotEligible,
  noDuplicates,
  nodeNotFound,
  nodeAlreadyUnlocked,
  previousNodeLocked,
  treeMaximized,
}

class ClashSkillTreeUnlockResult {
  const ClashSkillTreeUnlockResult({
    required this.cardId,
    required this.nodeId,
    required this.duplicateConsumed,
    required this.remainingDuplicates,
    required this.unlocked,
    this.boostLabel,
    this.error,
  });

  final String cardId;
  final String nodeId;
  final bool duplicateConsumed;
  final int remainingDuplicates;
  final bool unlocked;
  final String? boostLabel;
  final ClashSkillTreeUnlockError? error;

  bool get succeeded => error == null && unlocked;
}
