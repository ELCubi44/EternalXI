import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';

/// Fallo al conceder una recompensa concreta.
class ClashFailedReward {
  const ClashFailedReward({required this.reward, required this.error});

  final ClashReward reward;
  final String error;
}

/// Resultado agregado de una concesión local (Fase 53).
class ClashRewardGrantResult {
  const ClashRewardGrantResult({
    this.grantedRewards = const [],
    this.failedRewards = const [],
    this.coinsAdded = 0,
    this.gemsAdded = 0,
    this.itemCounts = const {},
    this.newlyGrantedCardIds = const [],
    this.duplicateCardIds = const [],
    this.summaryText,
  });

  final List<ClashReward> grantedRewards;
  final List<ClashFailedReward> failedRewards;
  final int coinsAdded;
  final int gemsAdded;
  final Map<String, int> itemCounts;
  final List<String> newlyGrantedCardIds;
  final List<String> duplicateCardIds;
  final String? summaryText;

  bool get isFullyGranted => failedRewards.isEmpty;

  factory ClashRewardGrantResult.allFailed(
    List<ClashReward> rewards, {
    String error = 'grant_failed',
  }) {
    return ClashRewardGrantResult(
      failedRewards: rewards
          .map((reward) => ClashFailedReward(reward: reward, error: error))
          .toList(growable: false),
    );
  }
}
