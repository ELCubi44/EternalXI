/// Tipo de recompensa local concedible por [ClashLocalRewardGranter].
enum ClashRewardKind {
  coins,
  gems,
  expMaterial,
  techniqueBook,
  evolutionMaterial,
  ticket,
  cardMissing,
  cardDuplicate,
  featuredCard,
  starterRoster,
}

/// Recompensa unificada de Clash (Fase 53).
class ClashReward {
  const ClashReward({
    required this.kind,
    this.amount = 0,
    this.itemId,
    this.featuredCardAsDuplicate = false,
    this.starterRosterKey,
  });

  final ClashRewardKind kind;
  final int amount;
  final String? itemId;
  final bool featuredCardAsDuplicate;
  final String? starterRosterKey;

  factory ClashReward.coins(int amount) =>
      ClashReward(kind: ClashRewardKind.coins, amount: amount);

  factory ClashReward.gems(int amount) =>
      ClashReward(kind: ClashRewardKind.gems, amount: amount);

  factory ClashReward.expMaterial(String id, int quantity) => ClashReward(
    kind: ClashRewardKind.expMaterial,
    itemId: id,
    amount: quantity,
  );

  factory ClashReward.techniqueBook(String id, int quantity) => ClashReward(
    kind: ClashRewardKind.techniqueBook,
    itemId: id,
    amount: quantity,
  );

  factory ClashReward.evolutionMaterial(String id, int quantity) => ClashReward(
    kind: ClashRewardKind.evolutionMaterial,
    itemId: id,
    amount: quantity,
  );

  factory ClashReward.ticket(String id, int quantity) =>
      ClashReward(kind: ClashRewardKind.ticket, itemId: id, amount: quantity);

  factory ClashReward.cardMissing(String cardId) =>
      ClashReward(kind: ClashRewardKind.cardMissing, itemId: cardId);

  factory ClashReward.cardDuplicate(String cardId) =>
      ClashReward(kind: ClashRewardKind.cardDuplicate, itemId: cardId);

  factory ClashReward.featuredCard(
    String cardId, {
    bool asDuplicateOnly = false,
  }) => ClashReward(
    kind: ClashRewardKind.featuredCard,
    itemId: cardId,
    featuredCardAsDuplicate: asDuplicateOnly,
  );

  factory ClashReward.starterRoster(String key) =>
      ClashReward(kind: ClashRewardKind.starterRoster, starterRosterKey: key);
}
