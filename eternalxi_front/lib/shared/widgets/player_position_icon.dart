import 'package:flutter/material.dart';

/// Icono de posición en la ficha de jugador.
class PlayerPositionIcon extends StatelessWidget {
  const PlayerPositionIcon({super.key, this.size = 16});

  static const asset = 'assets/app/player_position.png';

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
