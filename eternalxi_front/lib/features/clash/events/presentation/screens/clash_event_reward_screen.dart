import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_icon.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_feedback.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventRewardScreen extends StatefulWidget {
  const ClashEventRewardScreen({
    required this.eventId,
    required this.stageId,
    super.key,
  });

  final String eventId;
  final String stageId;

  @override
  State<ClashEventRewardScreen> createState() => _ClashEventRewardScreenState();
}

class _ClashEventRewardScreenState extends State<ClashEventRewardScreen> {
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
    final repo = context.read<ClashCharacterEventsRepository>();
    final completion = repo.lastCompletion;
    if (completion == null) {
      return;
    }
    _historyRecorded = true;
    final l10n = context.l10n;
    final title = completion.firstClear
        ? l10n.clashEventsRewardFirstClear
        : l10n.clashEventsRewardRepeat;
    ClashRewardFeedback.recordCompletionScreenHistory(
      context,
      sourceType: ClashRewardHistorySourceType.event,
      sourceId: '${widget.eventId}:${widget.stageId}',
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
    final theme = Theme.of(context);
    final repo = context.read<ClashCharacterEventsRepository>();
    final completion = repo.lastCompletion;
    final rewards =
        completion?.rewardsGranted ?? const ClashCharacterEventReward();
    final cardsRepo = _optionalCardsRepository(context);
    final feedbackTitle = completion?.firstClear == true
        ? l10n.clashEventsRewardFirstClear
        : l10n.clashEventsRewardRepeat;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashEventsRewardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            feedbackTitle,
            style: theme.textTheme.headlineSmall?.copyWith(
              ),
          ),
          const SizedBox(height: 16),
          _EventGrantedRewards(
            rewards: rewards,
            completion: completion,
            cardsRepo: cardsRepo,
          ),
          if (completion != null && completion.cardXpResults.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.clashMatchCardXpTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                ),
            ),
            const SizedBox(height: 8),
            for (final xp in completion.cardXpResults)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${xp.cardName}: +${xp.xpGained} XP',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.clashRewardFeedbackAccept),
          ),
        ],
      ),
    );
  }
}

class _EventGrantedRewards extends StatelessWidget {
  const _EventGrantedRewards({
    required this.rewards,
    required this.completion,
    required this.cardsRepo,
  });

  final ClashCharacterEventReward rewards;
  final ClashCharacterEventStageCompletionResult? completion;
  final ClashCardsRepository? cardsRepo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final newlyGranted = completion?.newlyGrantedCardIds ?? const [];
    final showGrantedCards = newlyGranted.isNotEmpty;

    var items = ClashRewardDisplayBuilder.fromCharacterEventReward(
      rewards,
      l10n,
    );

    if (showGrantedCards) {
      items = items
          .where(
            (item) =>
                item.label != l10n.clashRewardLabelFeaturedCard &&
                item.label != l10n.clashRewardLabelCardDuplicate,
          )
          .toList(growable: false);
    }

    if (showGrantedCards && cardsRepo != null) {
      return FutureBuilder(
        future: cardsRepo!.fetchAllCards(),
        builder: (context, snapshot) {
          final cardItems = _cardItemsFromIds(
            newlyGranted,
            snapshot.hasData
                ? {for (final card in snapshot.data!) card.id: card.name}
                : null,
          );
          return ClashRewardList(
            items: [...items, ...cardItems],
            layout: ClashRewardListLayout.column,
          );
        },
      );
    }

    if (showGrantedCards) {
      return ClashRewardList(
        items: [...items, ..._cardItemsFromIds(newlyGranted, null)],
        layout: ClashRewardListLayout.column,
      );
    }

    if (rewards.featuredCardId != null && rewards.featuredCardAsDuplicate) {
      final duplicateAlreadyShown = items.any(
        (item) => item.label == l10n.clashRewardLabelCardDuplicate,
      );
      if (!duplicateAlreadyShown) {
        items = [
          ...items,
          ClashRewardDisplayItem(
            icon: ClashRewardIcon.forKind(ClashRewardKind.cardDuplicate),
            label: l10n.clashRewardLabelCardDuplicate,
            detail: rewards.featuredCardId,
          ),
        ];
      }
    }

    return ClashRewardList(items: items, layout: ClashRewardListLayout.column);
  }

  List<ClashRewardDisplayItem> _cardItemsFromIds(
    List<String> cardIds,
    Map<String, String>? namesById,
  ) {
    return cardIds
        .map(
          (cardId) => ClashRewardDisplayItem(
            icon: ClashRewardIcon.forKind(ClashRewardKind.cardMissing),
            label: namesById?[cardId] ?? cardId,
            detail: namesById != null ? null : cardId,
          ),
        )
        .toList(growable: false);
  }
}

ClashCardsRepository? _optionalCardsRepository(BuildContext context) {
  try {
    return context.read<ClashCardsRepository>();
  } on ProviderNotFoundException {
    return null;
  }
}
