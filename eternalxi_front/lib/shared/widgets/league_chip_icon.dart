import 'package:flutter/material.dart';

/// Ficha de puntos de recompensa de una liga.
class LeagueChipIcon extends StatelessWidget {
  const LeagueChipIcon({super.key, this.size = 22});

  static const asset = 'assets/app/league_chip.png';

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
