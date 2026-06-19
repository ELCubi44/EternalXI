import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';

String clashEventStageTypeLabel(
  ClashCharacterEventStageType type,
  AppLocalizations l10n,
) {
  return switch (type) {
    ClashCharacterEventStageType.story => l10n.clashEventsStageTypeStory,
    ClashCharacterEventStageType.match => l10n.clashEventsStageTypeMatch,
  };
}

String clashEventStageStatusLabel(
  ClashCharacterEventStageStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    ClashCharacterEventStageStatus.locked => l10n.clashEventsStageLocked,
    ClashCharacterEventStageStatus.available => l10n.clashEventsStageAvailable,
    ClashCharacterEventStageStatus.completed => l10n.clashEventsStageCompleted,
  };
}

String clashEventStageActionLabel({
  required ClashCharacterEventStage stage,
  required ClashCharacterEventStageProgress progress,
  required AppLocalizations l10n,
}) {
  if (!progress.canPlay) {
    return l10n.clashEventsStageLocked;
  }
  return switch (stage.type) {
    ClashCharacterEventStageType.story =>
      progress.status == ClashCharacterEventStageStatus.completed
          ? l10n.clashEventsStageReadAgain
          : l10n.clashEventsStageRead,
    ClashCharacterEventStageType.match =>
      progress.clearCount > 0
          ? l10n.clashEventsStageRepeat
          : l10n.clashEventsStagePrepare,
  };
}
