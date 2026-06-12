import 'package:flutter/material.dart';

/// Icono de cartas de recompensa (tienda e historial).
class RewardCardsIcon extends StatelessWidget {
  const RewardCardsIcon({super.key, this.size = 22});

  static const asset = 'assets/app/reward_cards.png';

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
  }
}
