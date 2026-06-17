import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';

/// Objetivo opcional u obligatorio de un nivel match Clash.
class ClashMatchObjective {
  const ClashMatchObjective({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.rewards = const ClashStoryReward(),
    this.requiredStyle,
    this.requiredTechniqueType,
    this.requiredPlayerId,
    this.isMandatory = false,
  });

  final String id;
  final ClashMatchObjectiveType type;
  final String title;
  final String description;
  final ClashStoryReward rewards;
  final ClashPlayerStyle? requiredStyle;
  final ClashTechniqueType? requiredTechniqueType;
  final int? requiredPlayerId;
  final bool isMandatory;

  factory ClashMatchObjective.fromJson(Map<String, dynamic> json) {
    return ClashMatchObjective(
      id: clashRequireString(json['id'], 'id'),
      type: ClashMatchObjectiveType.fromJson(json['type']),
      title: clashRequireString(json['title'], 'title'),
      description: clashRequireString(json['description'], 'description'),
      rewards: ClashStoryReward.fromJson(
        Map<String, dynamic>.from(json['rewards'] as Map? ?? const {}),
      ),
      requiredStyle: json['requiredStyle'] == null
          ? null
          : ClashPlayerStyle.fromJson(json['requiredStyle']),
      requiredTechniqueType: json['requiredTechniqueType'] == null
          ? null
          : ClashTechniqueType.fromJson(json['requiredTechniqueType']),
      requiredPlayerId: json['requiredPlayerId'] == null
          ? null
          : clashAsInt(json['requiredPlayerId']),
      isMandatory: json['isMandatory'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.toJson(),
    'title': title,
    'description': description,
    'rewards': rewards.toJson(),
    if (requiredStyle != null) 'requiredStyle': requiredStyle!.toJson(),
    if (requiredTechniqueType != null)
      'requiredTechniqueType': requiredTechniqueType!.toJson(),
    if (requiredPlayerId != null) 'requiredPlayerId': requiredPlayerId,
    if (isMandatory) 'isMandatory': isMandatory,
  };
}
