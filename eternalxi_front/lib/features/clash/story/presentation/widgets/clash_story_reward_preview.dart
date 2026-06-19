import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/story/domain/clash_story_reward.dart';
import 'package:flutter/material.dart';

/// Vista resumida de recompensas first clear (Fase 49).
class ClashStoryRewardPreview extends StatelessWidget {
  const ClashStoryRewardPreview({
    required this.rewards,
    this.title,
    this.muted = false,
    super.key,
  });

  final ClashStoryReward rewards;
  final String? title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty && rewards.starterRosterKey == null) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lines = _lines(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Text(
            title!,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: muted ? context.xiTextSecondary : null,
            ),
          ),
        if (title != null) const SizedBox(height: 8),
        if (lines.isEmpty && rewards.starterRosterKey != null)
          _LineTile(
            icon: Icons.style_outlined,
            label: l10n.clashStoryCardsReceived,
            muted: muted,
          )
        else
          ...lines.map(
            (line) =>
                _LineTile(icon: line.icon, label: line.label, muted: muted),
          ),
      ],
    );
  }

  List<_RewardLine> _lines(BuildContext context) {
    final l10n = context.l10n;
    final lines = <_RewardLine>[];
    if (rewards.gems > 0) {
      lines.add(
        _RewardLine(
          Icons.diamond_outlined,
          l10n.clashMatchRewardGems(rewards.gems),
        ),
      );
    }
    if (rewards.coins > 0) {
      lines.add(
        _RewardLine(
          Icons.monetization_on_outlined,
          l10n.clashMatchRewardCoins(rewards.coins),
        ),
      );
    }
    for (final item in rewards.items) {
      lines.add(
        _RewardLine(
          Icons.inventory_2_outlined,
          '${item.name} x${item.quantity}',
        ),
      );
    }
    for (final material in rewards.materials) {
      lines.add(
        _RewardLine(
          Icons.science_outlined,
          '${material.name} x${material.quantity}',
        ),
      );
    }
    if (rewards.cardIds.isNotEmpty) {
      lines.add(
        _RewardLine(
          Icons.person_outline,
          l10n.clashMatchRewardCards(rewards.cardIds.length),
        ),
      );
    }
    return lines;
  }
}

class _RewardLine {
  const _RewardLine(this.icon, this.label);

  final IconData icon;
  final String label;
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.icon,
    required this.label,
    required this.muted,
  });

  final IconData icon;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: muted
                ? context.xiTextSecondary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: muted ? context.xiTextSecondary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
