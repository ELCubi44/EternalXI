import 'package:flutter/material.dart';

/// Icono de ajustes de liga (cabecera superior derecha).
class LeagueSettingsIcon extends StatelessWidget {
  const LeagueSettingsIcon({super.key, this.size = 24});

  static const asset = 'assets/app/league_settings.png';

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
