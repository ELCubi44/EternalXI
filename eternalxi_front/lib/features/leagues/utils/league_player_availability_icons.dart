import 'package:eternal_xi/shared/widgets/player_injury_icon.dart';
import 'package:flutter/material.dart';

/// Iconos unificados para lesión y sanción (plantilla, alineación, ficha).
abstract final class LeaguePlayerAvailabilityIcons {
  static const IconData sanctioned = Icons.style;

  static Widget injured({double size = 20}) => PlayerInjuryIcon(size: size);
}
