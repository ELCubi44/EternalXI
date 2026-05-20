import 'package:eternal_xi/features/rewards/data/models/reward_card_model.dart';
import 'package:eternal_xi/features/rewards/presentation/widgets/reward_card_tile.dart';
import 'package:flutter/material.dart';

class RewardCardGrid extends StatelessWidget {
  const RewardCardGrid({
    super.key,
    required this.cards,
    required this.onUse,
    required this.onTap,
  });

  final List<RewardCardModel> cards;
  final void Function(RewardCardModel card) onUse;
  final void Function(RewardCardModel card) onTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            'No tienes cartas en esta liga todavía. Abre sobres para conseguir cartas.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              height: 1.35,
            ),
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cross = w >= 520 ? 3 : 2;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
          ),
          itemCount: cards.length,
          itemBuilder: (_, i) {
            final card = cards[i];
            return RewardCardTile(
              card: card,
              onUse: card.isAvailable ? () => onUse(card) : null,
              onTap: () => onTap(card),
            );
          },
        );
      },
    );
  }
}
