import 'package:eternal_xi/app/localization/rewards_l10n.dart';
import 'package:eternal_xi/features/rewards/data/models/reward_event_model.dart';
import 'package:eternal_xi/features/rewards/utils/reward_formatters.dart';
import 'package:flutter/material.dart';

class RewardEventTile extends StatelessWidget {
  const RewardEventTile({super.key, required this.event});

  final RewardEventModel event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rl10n = context.rewardsL10n;
    final dateStr = formatRewardDateTime(context, event.creadoEn);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF151A28).withValues(alpha: 0.95),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rl10n.rewardEventTypeLabel(event.tipo),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            rl10n.rewardEventDescription(event),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white70,
              height: 1.3,
            ),
          ),
          if (event.cantidad != null) ...[
            const SizedBox(height: 4),
            Text(
              rl10n.quantity(event.cantidad!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFFFD54F),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
