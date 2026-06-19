import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_stage_type.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_labels.dart';
import 'package:eternal_xi/features/clash/events/presentation/widgets/clash_event_reward_preview.dart';
import 'package:eternal_xi/features/clash/story/presentation/widgets/clash_story_level_status_chip.dart';
import 'package:flutter/material.dart';

/// Cabecera de fase story/match en evento (Fase 50).
class ClashEventStageDetailHeader extends StatelessWidget {
  const ClashEventStageDetailHeader({
    required this.eventTitle,
    required this.stage,
    required this.status,
    required this.clearCount,
    this.firstClearClaimed = false,
    super.key,
  });

  final String eventTitle;
  final ClashCharacterEventStage stage;
  final ClashCharacterEventStageStatus status;
  final int clearCount;
  final bool firstClearClaimed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          eventTitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: context.xiTextSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          stage.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ClashStoryLevelStatusChip(
              label: clashEventStageTypeLabel(stage.type, l10n),
              kind: ClashStoryLevelChipKind.type,
            ),
            ClashStoryLevelStatusChip(
              label: clashEventStageStatusLabel(status, l10n),
              kind: ClashStoryLevelChipKind.status,
            ),
            if (clearCount > 0)
              ClashStoryLevelStatusChip(
                label: l10n.clashEventsCompletedTimes(clearCount),
                kind: ClashStoryLevelChipKind.firstClearClaimed,
              )
            else if (stage.type == ClashCharacterEventStageType.match)
              ClashStoryLevelStatusChip(
                label: l10n.clashEventsRepeatable,
                kind: ClashStoryLevelChipKind.firstClear,
              ),
          ],
        ),
        if (!stage.firstClearRewards.isEmpty) ...[
          const SizedBox(height: 14),
          ClashEventRewardPreview(
            title: l10n.clashEventsFirstVictory,
            rewards: stage.firstClearRewards,
            muted: firstClearClaimed,
          ),
        ],
        if (!stage.repeatRewards.isEmpty) ...[
          const SizedBox(height: 12),
          ClashEventRewardPreview(
            title: l10n.clashEventsRepeats,
            rewards: stage.repeatRewards,
          ),
        ],
      ],
    );
  }
}
