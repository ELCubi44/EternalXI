import 'package:flutter/material.dart';

/// Icono de cansancio en la ficha de jugador.
class PlayerFatigueIcon extends StatelessWidget {
  const PlayerFatigueIcon({super.key, this.size = 16});

  static const asset = 'assets/app/player_fatigue.png';

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
