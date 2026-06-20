import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';

/// Origen de una entrada en el historial local de recompensas (Fase 60).
enum ClashRewardHistorySourceType {
  gift,
  achievement,
  dailyMission,
  weeklyMission,
  shop,
  event,
  story;

  String toJson() => name;

  static ClashRewardHistorySourceType fromJson(Object? value) {
    final raw = value?.toString().trim();
    return ClashRewardHistorySourceType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => ClashRewardHistorySourceType.gift,
    );
  }
}

/// Entrada persistida del historial local de recompensas Clash (Fase 60).
class ClashRewardHistoryEntry {
  const ClashRewardHistoryEntry({
    required this.id,
    required this.sourceType,
    required this.title,
    required this.createdAt,
    this.sourceId,
    this.rewards = const [],
    this.failedRewards = const [],
    this.isPartial = false,
    this.isFailure = false,
    this.newlyGrantedCardIds = const [],
    this.duplicateCardIds = const [],
  });

  final String id;
  final ClashRewardHistorySourceType sourceType;
  final String? sourceId;
  final String title;
  final DateTime createdAt;
  final List<ClashReward> rewards;
  final List<ClashFailedReward> failedRewards;
  final bool isPartial;
  final bool isFailure;
  final List<String> newlyGrantedCardIds;
  final List<String> duplicateCardIds;

  static const maxStoredEntries = 100;

  factory ClashRewardHistoryEntry.fromGrant({
    required String id,
    required ClashRewardHistorySourceType sourceType,
    required String title,
    required ClashRewardGrantResult result,
    String? sourceId,
    DateTime? createdAt,
  }) {
    final hasFailed = result.failedRewards.isNotEmpty;
    final hasGranted = result.grantedRewards.isNotEmpty;
    return ClashRewardHistoryEntry(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      rewards: result.grantedRewards,
      failedRewards: result.failedRewards,
      isPartial: hasFailed && hasGranted,
      isFailure: hasFailed && !hasGranted,
      newlyGrantedCardIds: result.newlyGrantedCardIds,
      duplicateCardIds: result.duplicateCardIds,
    );
  }

  factory ClashRewardHistoryEntry.failure({
    required String id,
    required ClashRewardHistorySourceType sourceType,
    required String title,
    String? sourceId,
    DateTime? createdAt,
  }) {
    return ClashRewardHistoryEntry(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
      title: title,
      createdAt: createdAt ?? DateTime.now().toUtc(),
      isFailure: true,
    );
  }

  factory ClashRewardHistoryEntry.fromJson(Map<String, dynamic> json) {
    final rewardsRaw = json['rewards'] as List? ?? const [];
    final failedRaw = json['failedRewards'] as List? ?? const [];
    return ClashRewardHistoryEntry(
      id: json['id'] as String? ?? '',
      sourceType: ClashRewardHistorySourceType.fromJson(json['sourceType']),
      sourceId: json['sourceId'] as String?,
      title: json['title'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      rewards: rewardsRaw
          .map(
            (item) => ClashRewardJson.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      failedRewards: failedRaw
          .map(
            (item) => ClashFailedRewardJson.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
      isPartial: json['isPartial'] as bool? ?? false,
      isFailure: json['isFailure'] as bool? ?? false,
      newlyGrantedCardIds: (json['newlyGrantedCardIds'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      duplicateCardIds: (json['duplicateCardIds'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceType': sourceType.toJson(),
    if (sourceId != null) 'sourceId': sourceId,
    'title': title,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'rewards': rewards.map(ClashRewardJson.toJson).toList(growable: false),
    'failedRewards': failedRewards
        .map(ClashFailedRewardJson.toJson)
        .toList(growable: false),
    'isPartial': isPartial,
    'isFailure': isFailure,
    'newlyGrantedCardIds': newlyGrantedCardIds,
    'duplicateCardIds': duplicateCardIds,
  };

  ClashRewardGrantResult toGrantResult() {
    return ClashRewardGrantResult(
      grantedRewards: rewards,
      failedRewards: failedRewards,
      newlyGrantedCardIds: newlyGrantedCardIds,
      duplicateCardIds: duplicateCardIds,
    );
  }
}

/// Serialización JSON de [ClashReward] para historial local.
abstract final class ClashRewardJson {
  static Map<String, dynamic> toJson(ClashReward reward) => {
    'kind': reward.kind.name,
    'amount': reward.amount,
    if (reward.itemId != null) 'itemId': reward.itemId,
    'featuredCardAsDuplicate': reward.featuredCardAsDuplicate,
    if (reward.starterRosterKey != null)
      'starterRosterKey': reward.starterRosterKey,
  };

  static ClashReward fromJson(Map<String, dynamic> json) {
    final kind = ClashRewardKind.values.firstWhere(
      (value) => value.name == json['kind']?.toString(),
      orElse: () => ClashRewardKind.coins,
    );
    return ClashReward(
      kind: kind,
      amount: json['amount'] as int? ?? 0,
      itemId: json['itemId'] as String?,
      featuredCardAsDuplicate:
          json['featuredCardAsDuplicate'] as bool? ?? false,
      starterRosterKey: json['starterRosterKey'] as String?,
    );
  }
}

abstract final class ClashFailedRewardJson {
  static Map<String, dynamic> toJson(ClashFailedReward failed) => {
    'reward': ClashRewardJson.toJson(failed.reward),
    'error': failed.error,
  };

  static ClashFailedReward fromJson(Map<String, dynamic> json) {
    return ClashFailedReward(
      reward: ClashRewardJson.fromJson(
        Map<String, dynamic>.from(json['reward'] as Map? ?? const {}),
      ),
      error: json['error'] as String? ?? 'grant_failed',
    );
  }
}
