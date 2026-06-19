import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Texto compacto de recompensa de un objetivo match.
String clashMatchObjectiveRewardPreview(
  BuildContext context,
  ClashStoryReward rewards,
) {
  if (rewards.isEmpty) {
    return '';
  }

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
  if (rewards.cardIds.isNotEmpty) {
    parts.add(l10n.clashMatchRewardCards(rewards.cardIds.length));
  }
  return parts.join(' · ');
}
