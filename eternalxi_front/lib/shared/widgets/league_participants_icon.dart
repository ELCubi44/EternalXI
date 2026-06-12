import 'package:flutter/material.dart';

/// Icono de participantes en la lista de ligas.
class LeagueParticipantsIcon extends StatelessWidget {
  const LeagueParticipantsIcon({super.key, this.size = 16});

  static const asset = 'assets/app/league_participants.png';

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
