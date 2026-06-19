import 'package:eternal_xi/app/localization/l10n_extension.dart';
import 'package:eternal_xi/app/theme/xi_theme_extension.dart';
import 'package:eternal_xi/features/clash/events/domain/clash_character_event_reward.dart';
import 'package:flutter/material.dart';

/// Vista resumida de recompensas de fase de evento (Fase 50).
class ClashEventRewardPreview extends StatelessWidget {
  const ClashEventRewardPreview({
    required this.rewards,
    this.title,
    this.muted = false,
    super.key,
  });

  final ClashCharacterEventReward rewards;
  final String? title;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return const SizedBox.shrink();
    }

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
        ...lines.map(
          (line) => _LineTile(icon: line.icon, label: line.label, muted: muted),
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
    if (rewards.expMaterial != null) {
      lines.add(
        _RewardLine(
          Icons.science_outlined,
          l10n.clashShopGrantLine(
            rewards.expMaterial!.id,
            rewards.expMaterial!.quantity,
          ),
        ),
      );
    }
    if (rewards.techniqueBook != null) {
      lines.add(
        _RewardLine(
          Icons.menu_book_outlined,
          l10n.clashShopGrantLine(
            rewards.techniqueBook!.id,
            rewards.techniqueBook!.quantity,
          ),
        ),
      );
    }
    if (rewards.evolutionMaterial != null) {
      lines.add(
        _RewardLine(
          Icons.upgrade_outlined,
          l10n.clashShopGrantLine(
            rewards.evolutionMaterial!.id,
            rewards.evolutionMaterial!.quantity,
          ),
        ),
      );
    }
    if (rewards.ticket != null) {
      lines.add(
        _RewardLine(
          Icons.confirmation_number_outlined,
          l10n.clashShopGrantLine(rewards.ticket!.id, rewards.ticket!.quantity),
        ),
      );
    }
    if (rewards.featuredCardId != null) {
      lines.add(
        _RewardLine(
          Icons.person_outline,
          rewards.featuredCardAsDuplicate
              ? l10n.clashEventsRewardDuplicate(rewards.featuredCardId!)
              : rewards.featuredCardId!,
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
