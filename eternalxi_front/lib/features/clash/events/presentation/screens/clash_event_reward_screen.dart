import 'package:eternal_xi/app/localization/app_localizations.dart';
import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_builder.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_display_item.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_icon.dart';
import 'package:eternal_xi/features/clash/shared/rewards/presentation/clash_reward_list.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashEventRewardScreen extends StatelessWidget {
  const ClashEventRewardScreen({
    required this.eventId,
    required this.stageId,
    super.key,
  });

  final String eventId;
  final String stageId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repo = context.read<ClashCharacterEventsRepository>();
    final completion = repo.lastCompletion;
    final rewards =
        completion?.rewardsGranted ?? const ClashCharacterEventReward();
    final cardsRepo = _optionalCardsRepository(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashEventsRewardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            completion?.firstClear == true
                ? l10n.clashEventsRewardFirstClear
                : l10n.clashEventsRewardRepeat,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final xp in completion.cardXpResults)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${xp.cardName}: +${xp.xpGained} XP',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.pop(),
            child: Text(l10n.clashEventsRewardContinue),
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
            l10n,
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
        items: [...items, ..._cardItemsFromIds(l10n, newlyGranted, null)],
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
    AppLocalizations l10n,
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
