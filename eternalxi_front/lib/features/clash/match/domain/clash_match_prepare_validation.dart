import 'package:eternal_xi/features/clash/story/domain/clash_story_level.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_progress.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';

/// Resultado de validación para preparación de partido match.
class ClashMatchPrepareValidation {
  const ClashMatchPrepareValidation({
    required this.canEnter,
    required this.canStart,
    required this.teamUnlocked,
    required this.hasCompleteActiveLineup,
    required this.lineupPower,
    required this.recommendedPower,
    required this.powerBelowRecommended,
    this.activeLineup,
  });

  final bool canEnter;
  final bool canStart;
  final bool teamUnlocked;
  final bool hasCompleteActiveLineup;
  final int lineupPower;
  final int? recommendedPower;
  final bool powerBelowRecommended;
  final ClashLineup7v7? activeLineup;

  static ClashMatchPrepareValidation evaluate({
    required ClashStoryLevel level,
    required ClashStoryProgress progress,
    required ClashLineup7v7? activeLineup,
    required int lineupPower,
  }) {
    final teamUnlocked =
        !level.requirements.clashTeamUnlocked || progress.clashTeamUnlocked;
    final hasComplete = activeLineup?.isComplete ?? false;
    final needsLineup = level.requirements.completeActiveLineup;
    final recommended = level.recommendedPower;
    final belowRecommended = recommended != null && lineupPower < recommended;

    return ClashMatchPrepareValidation(
      canEnter: teamUnlocked,
      canStart: teamUnlocked && (!needsLineup || hasComplete),
      teamUnlocked: teamUnlocked,
      hasCompleteActiveLineup: hasComplete,
      lineupPower: lineupPower,
      recommendedPower: recommended,
      powerBelowRecommended: belowRecommended,
      activeLineup: activeLineup,
    );
  }
}
