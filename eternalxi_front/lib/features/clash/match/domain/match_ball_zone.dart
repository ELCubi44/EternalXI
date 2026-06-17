import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Zona lógica del balón en el minicampo (perspectiva Eternal XI abajo).
enum MatchBallZone {
  ownDefense,
  ownMidfield,
  midfield,
  rivalMidfield,
  rivalArea;

  int get order => index;

  /// Coordenada Y normalizada aproximada del balón en la zona.
  double get normalizedY => switch (this) {
    MatchBallZone.ownDefense => 0.86,
    MatchBallZone.ownMidfield => 0.68,
    MatchBallZone.midfield => 0.50,
    MatchBallZone.rivalMidfield => 0.35,
    MatchBallZone.rivalArea => 0.20,
  };

  String labelEs() => switch (this) {
    MatchBallZone.ownDefense => 'Defensa propia',
    MatchBallZone.ownMidfield => 'Medio propio',
    MatchBallZone.midfield => 'Centro del campo',
    MatchBallZone.rivalMidfield => 'Medio rival',
    MatchBallZone.rivalArea => 'Área rival',
  };

  static MatchBallZone forPositionIndex(int index) {
    return switch (index) {
      <= 2 => MatchBallZone.ownDefense,
      3 => MatchBallZone.ownMidfield,
      4 => MatchBallZone.midfield,
      5 => MatchBallZone.rivalMidfield,
      _ => MatchBallZone.rivalArea,
    };
  }

  MatchBallZone advanceFor(MatchTeamSide side) {
    if (side == MatchTeamSide.user) {
      final next = order + 1;
      return MatchBallZone.values[next.clamp(0, values.length - 1)];
    }
    final prev = order - 1;
    return MatchBallZone.values[prev.clamp(0, values.length - 1)];
  }
}
