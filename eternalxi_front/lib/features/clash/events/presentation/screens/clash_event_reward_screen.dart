import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/events/data/clash_character_events_repository.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
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
          if (rewards.gems > 0)
            _RewardRow(
              icon: Icons.diamond_rounded,
              label: l10n.clashStoryRewardGems(rewards.gems),
            ),
          if (rewards.coins > 0)
            _RewardRow(
              icon: Icons.paid_rounded,
              label: l10n.clashStoryRewardCoins(rewards.coins),
            ),
          if (rewards.expMaterial != null)
            _RewardRow(
              icon: Icons.inventory_2_rounded,
              label: l10n.clashShopGrantLine(
                rewards.expMaterial!.id,
                rewards.expMaterial!.quantity,
              ),
            ),
          if (rewards.techniqueBook != null)
            _RewardRow(
              icon: Icons.menu_book_rounded,
              label: l10n.clashShopGrantLine(
                rewards.techniqueBook!.id,
                rewards.techniqueBook!.quantity,
              ),
            ),
          if (completion != null &&
              completion.newlyGrantedCardIds.isNotEmpty &&
              cardsRepo != null)
            FutureBuilder(
              future: cardsRepo.fetchAllCards(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final byId = {for (final card in snapshot.data!) card.id: card};
                return Column(
                  children: [
                    for (final cardId in completion.newlyGrantedCardIds)
                      _RewardRow(
                        icon: Icons.style_rounded,
                        label: byId[cardId]?.name ?? cardId,
                      ),
                  ],
                );
              },
            )
          else if (completion != null &&
              completion.newlyGrantedCardIds.isNotEmpty)
            for (final cardId in completion.newlyGrantedCardIds)
              _RewardRow(icon: Icons.style_rounded, label: cardId)
          else if (rewards.featuredCardId != null &&
              rewards.featuredCardAsDuplicate)
            _RewardRow(
              icon: Icons.copy_rounded,
              label: l10n.clashEventsRewardDuplicate(rewards.featuredCardId!),
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

ClashCardsRepository? _optionalCardsRepository(BuildContext context) {
  try {
    return context.read<ClashCardsRepository>();
  } on ProviderNotFoundException {
    return null;
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.xiTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
