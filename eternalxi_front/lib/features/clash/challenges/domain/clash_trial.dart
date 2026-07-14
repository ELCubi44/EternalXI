import 'package:eternal_xi/features/clash/cards/domain/clash_card_xp_result.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/challenges/domain/clash_trial_line.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

class ClashTrial {
  const ClashTrial({
    required this.id,
    required this.title,
    required this.description,
    required this.line,
    required this.floors,
    this.order = 0,
  });

  final String id;
  final String title;
  final String description;
  final ClashTrialLine line;
  final List<ClashTrialFloor> floors;
  final int order;

  factory ClashTrial.fromJson(Map<String, dynamic> json) {
    final floorsRaw = json['floors'];
    if (floorsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: floors');
    }
    return ClashTrial(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: json['description']?.toString() ?? '',
      line: ClashTrialLine.fromJson(json['line']),
      order: clashAsInt(json['order']),
      floors: floorsRaw
          .map(
            (item) => ClashTrialFloor.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class ClashTrialFloor {
  const ClashTrialFloor({
    required this.id,
    required this.title,
    required this.description,
    required this.order,
    required this.baseRecommendedPower,
    required this.powerScalePerClear,
    required this.moments,
    required this.firstClearRewards,
    required this.repeatRewards,
    this.rivalTeamId,
    this.cardXpReward = 0,
    this.techniqueBonusTarget = 0,
    this.techniqueBonusRewards = const ClashCharacterEventReward(),
  });

  final String id;
  final String title;
  final String description;
  final int order;
  final int baseRecommendedPower;
  final int powerScalePerClear;
  final String? rivalTeamId;
  final int cardXpReward;
  final int techniqueBonusTarget;
  final ClashCharacterEventReward techniqueBonusRewards;
  final List<ClashDecisiveMoment> moments;
  final ClashCharacterEventReward firstClearRewards;
  final ClashCharacterEventReward repeatRewards;

  int scaledRecommendedPower(int clearCount) {
    return baseRecommendedPower + clearCount * powerScalePerClear;
  }

  factory ClashTrialFloor.fromJson(Map<String, dynamic> json) {
    final momentsRaw = json['moments'];
    final moments = momentsRaw is List && momentsRaw.isNotEmpty
        ? momentsRaw
              .map(
                (item) => _momentFromJson(
                  Map<String, dynamic>.from(item as Map),
                ),
              )
              .toList(growable: false)
        : ClashDecisiveMomentScript.defaultMoments;

    return ClashTrialFloor(
      id: clashRequireString(json['id'], 'id'),
      title: clashRequireString(json['title'], 'title'),
      description: json['description']?.toString() ?? '',
      order: clashAsInt(json['order']),
      baseRecommendedPower: clashAsInt(json['baseRecommendedPower']),
      powerScalePerClear: clashAsInt(json['powerScalePerClear']),
      rivalTeamId: clashOptionalString(json['rivalTeamId']),
      cardXpReward: clashAsInt(json['cardXpReward']),
      techniqueBonusTarget: clashAsInt(json['techniqueBonusTarget']),
      techniqueBonusRewards: ClashCharacterEventReward.fromJson(
        Map<String, dynamic>.from(
          json['techniqueBonusRewards'] as Map? ?? const {},
        ),
      ),
      moments: moments,
      firstClearRewards: ClashCharacterEventReward.fromJson(
        Map<String, dynamic>.from(
          json['firstClearRewards'] as Map? ?? const {},
        ),
      ),
      repeatRewards: ClashCharacterEventReward.fromJson(
        Map<String, dynamic>.from(json['repeatRewards'] as Map? ?? const {}),
      ),
    );
  }
}

ClashDecisiveMoment _momentFromJson(Map<String, dynamic> json) {
  final preferredRaw = json['preferredPositions'];
  final preferred = <ClashPosition>[];
  if (preferredRaw is List) {
    for (final item in preferredRaw) {
      preferred.add(ClashPosition.fromJson(item));
    }
  }

  return ClashDecisiveMoment(
    index: clashAsInt(json['index']),
    minute: clashAsInt(json['minute']),
    title: clashRequireString(json['title'], 'title'),
    context: json['context']?.toString() ?? '',
    duelType: _duelTypeFromJson(json['duelType']),
    attackerSide: _teamSideFromJson(json['attackerSide']),
    ballZone: _ballZoneFromJson(json['ballZone']),
    preferredPositions: preferred,
  );
}

ClashDuelType _duelTypeFromJson(Object? value) {
  final raw = value?.toString().trim();
  return switch (raw) {
    'dribbleVsDefense' || 'regate' => ClashDuelType.dribbleVsDefense,
    'shotVsSave' || 'tiro' => ClashDuelType.shotVsSave,
    _ => ClashDuelType.dribbleVsDefense,
  };
}

MatchTeamSide _teamSideFromJson(Object? value) {
  final raw = value?.toString().trim().toLowerCase();
  return raw == 'rival' ? MatchTeamSide.rival : MatchTeamSide.user;
}

MatchBallZone _ballZoneFromJson(Object? value) {
  final raw = value?.toString().trim();
  for (final zone in MatchBallZone.values) {
    if (zone.name == raw) {
      return zone;
    }
  }
  return MatchBallZone.midfield;
}

enum ClashTrialFloorStatus { locked, available, completed }

class ClashTrialFloorProgress {
  const ClashTrialFloorProgress({
    required this.floor,
    required this.status,
    required this.clearCount,
    required this.canPlay,
    required this.scaledPower,
  });

  final ClashTrialFloor floor;
  final ClashTrialFloorStatus status;
  final int clearCount;
  final bool canPlay;
  final int scaledPower;
}

class ClashTrialSummary {
  const ClashTrialSummary({
    required this.trial,
    required this.completedFloors,
    required this.totalFloors,
    required this.bestClearCount,
  });

  final ClashTrial trial;
  final int completedFloors;
  final int totalFloors;
  final int bestClearCount;
}

class ClashTrialFloorCompletionResult {
  const ClashTrialFloorCompletionResult({
    required this.trialId,
    required this.floorId,
    required this.firstClear,
    required this.rewardsGranted,
    required this.newlyGrantedCardIds,
    required this.techniqueBonusGranted,
    required this.techniqueBonusRewards,
    this.cardXpResults = const [],
  });

  final String trialId;
  final String floorId;
  final bool firstClear;
  final ClashCharacterEventReward rewardsGranted;
  final List<String> newlyGrantedCardIds;
  final bool techniqueBonusGranted;
  final ClashCharacterEventReward techniqueBonusRewards;
  final List<ClashCardXpResult> cardXpResults;
}
