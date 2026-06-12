import 'package:eternal_xi/shared/widgets/player_injury_icon.dart';
import 'package:eternal_xi/shared/widgets/red_card_icon.dart';
import 'package:flutter/material.dart';

/// Iconos unificados para lesión y sanción (plantilla, alineación, ficha).
abstract final class LeaguePlayerAvailabilityIcons {
  static Widget injured({double size = 20}) => PlayerInjuryIcon(size: size);

  static Widget sanctioned({double size = 22}) => RedCardIcon(size: size);
}
