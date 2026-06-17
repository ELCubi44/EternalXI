import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/routes.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_level_type.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ClashStoryRewardScreen extends StatelessWidget {
  const ClashStoryRewardScreen({required this.levelId, super.key});

  final String levelId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final controller = context.watch<ClashStoryController>();
    final completion = controller.lastCompletion;
    final rewards = completion?.rewardsGranted ?? const ClashStoryReward();
    final cardsRepo = context.read<ClashCardsRepository>();
    final nextLevel = controller.nextUnlockedLevelAfter(levelId);
    final isTeamFormation =
        rewards.starterRosterKey != null &&
        (completion?.newlyGrantedCardIds.isNotEmpty == true ||
            controller.progress.eternalXiCardsGranted);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.clashStoryRewardTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            l10n.clashStoryRewardTitle,
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
          for (final item in rewards.items)
            _RewardRow(
              icon: Icons.inventory_2_rounded,
              label: '${item.name} x${item.quantity}',
            ),
          if (isTeamFormation) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.xiCardSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.xiDivider),
              ),
              child: Text(
                l10n.clashStoryTeamFormed,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
          if (completion != null && completion.newlyGrantedCardIds.isNotEmpty)
            FutureBuilder(
              future: cardsRepo.fetchAllCards(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                final names = snapshot.data!
                    .where(
                      (entry) =>
                          completion.newlyGrantedCardIds.contains(entry.id),
                    )
                    .map((entry) => entry.name)
                    .toList();
                if (names.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      l10n.clashStoryCardsReceived,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...names.map(
                      (name) =>
                          _RewardRow(icon: Icons.style_rounded, label: name),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              controller.clearActiveLevel();
              controller.clearLastCompletion();
              context.go(AppRoutes.clashStory);
            },
            child: Text(l10n.clashStoryBackToMap),
          ),
          if (nextLevel != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                controller.clearActiveLevel();
                controller.clearLastCompletion();
                final route = nextLevel.type == ClashStoryLevelType.story
                    ? AppRoutes.clashStoryLevel(nextLevel.id)
                    : AppRoutes.clashStoryLevelPrepare(nextLevel.id);
                context.push(route);
              },
              child: Text(l10n.clashStoryNextLevel),
            ),
          ],
        ],
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
