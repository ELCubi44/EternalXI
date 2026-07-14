import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/challenges/data/clash_trials_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashTrialRewardScreen extends StatefulWidget {
  const ClashTrialRewardScreen({
    required this.trialId,
    required this.floorId,
    super.key,
  });

  final String trialId;
  final String floorId;

  @override
  State<ClashTrialRewardScreen> createState() => _ClashTrialRewardScreenState();
}

class _ClashTrialRewardScreenState extends State<ClashTrialRewardScreen> {
  var _historyRecorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recordHistoryOnce());
  }

  void _recordHistoryOnce() {
    if (_historyRecorded || !mounted) {
      return;
    }
    final repo = context.read<ClashTrialsRepository>();
    final completion = repo.lastCompletion;
    if (completion == null) {
      return;
    }
    _historyRecorded = true;
    final l10n = context.l10n;
    final title = completion.firstClear
        ? l10n.clashTrialsRewardFirstClear
        : l10n.clashTrialsRewardRepeat;
    ClashRewardFeedback.recordCompletionScreenHistory(
      context,
      sourceType: ClashRewardHistorySourceType.event,
      sourceId: '${widget.trialId}:${widget.floorId}',
      title: title,
      result: ClashRewardFeedback.fromCharacterEventReward(
        completion.rewardsGranted,
        newlyGrantedCardIds: completion.newlyGrantedCardIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<ClashTrialsRepository>();
    final completion = repo.lastCompletion;
    final rewards =
        completion?.rewardsGranted ?? const ClashCharacterEventReward();

    final items = [
      ...ClashRewardDisplayBuilder.fromCharacterEventReward(rewards, l10n),
      if (completion?.techniqueBonusGranted == true &&
          !completion!.techniqueBonusRewards.isEmpty)
        ...ClashRewardDisplayBuilder.fromCharacterEventReward(
          completion.techniqueBonusRewards,
          l10n,
        ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          completion?.firstClear == true
              ? l10n.clashTrialsRewardFirstClear
              : l10n.clashTrialsRewardRepeat,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (completion?.techniqueBonusGranted == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(l10n.clashTrialsRewardTechniqueBonus),
            ),
          ClashRewardList(items: items),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.clashRewardFeedbackAccept),
          ),
        ],
      ),
    );
  }
}
