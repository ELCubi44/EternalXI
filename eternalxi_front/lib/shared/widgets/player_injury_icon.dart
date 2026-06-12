import 'package:flutter/material.dart';

/// Icono de lesión (botiquín) en cronología, plantilla y ficha.
class PlayerInjuryIcon extends StatelessWidget {
  const PlayerInjuryIcon({super.key, this.size = 20});

  static const asset = 'assets/app/player_injury.png';

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
