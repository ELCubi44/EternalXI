import 'package:flutter/material.dart';

/// Estrella de valoración en la ficha de jugador.
class PlayerRatingStarIcon extends StatelessWidget {
  const PlayerRatingStarIcon({super.key, this.size = 16});

  static const asset = 'assets/app/player_rating_star.png';

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
