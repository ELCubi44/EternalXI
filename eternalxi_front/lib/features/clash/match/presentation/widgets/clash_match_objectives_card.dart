import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_match_objective.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Lista de objetivos de un nivel match en preparación (Fase 16).
class ClashMatchObjectivesCard extends StatelessWidget {
  const ClashMatchObjectivesCard({required this.objectives, super.key});

  final List<ClashMatchObjective> objectives;

  @override
  Widget build(BuildContext context) {
    if (objectives.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.xiCardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.xiDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.clashMatchObjectivesTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...objectives.map((objective) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    objective.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    objective.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: context.xiTextSecondary,
                    ),
                  ),
                  if (!objective.rewards.isEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _rewardPreview(context, objective.rewards),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _rewardPreview(BuildContext context, ClashStoryReward rewards) {
    final l10n = context.l10n;
    final parts = <String>[];
    if (rewards.gems > 0) {
      parts.add(l10n.clashMatchRewardGems(rewards.gems));
    }
    if (rewards.coins > 0) {
      parts.add(l10n.clashMatchRewardCoins(rewards.coins));
    }
    for (final item in rewards.items) {
      parts.add('${item.name} x${item.quantity}');
    }
    for (final material in rewards.materials) {
      parts.add('${material.name} x${material.quantity}');
    }
    return parts.join(' · ');
  }
}
