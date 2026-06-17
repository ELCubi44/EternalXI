import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Posiciones placeholder del minicampo 7vs7 (normalizadas).
class MatchPitchLayout {
  const MatchPitchLayout._();

  static const List<(double x, double y)> _userFormation = [
    (0.5, 0.88),
    (0.25, 0.72),
    (0.75, 0.72),
    (0.35, 0.55),
    (0.65, 0.55),
    (0.25, 0.38),
    (0.75, 0.38),
  ];

  static const List<(double x, double y)> _rivalFormation = [
    (0.5, 0.12),
    (0.25, 0.28),
    (0.75, 0.28),
    (0.35, 0.45),
    (0.65, 0.45),
    (0.25, 0.62),
    (0.75, 0.62),
  ];

  static List<MatchPlayerMarker> defaultUserMarkers() {
    return List.generate(_userFormation.length, (index) {
      final (x, y) = _userFormation[index];
      return MatchPlayerMarker(
        side: MatchTeamSide.user,
        index: index,
        label: 'U${index + 1}',
        x: x,
        y: y,
      );
    });
  }

  static List<MatchPlayerMarker> defaultRivalMarkers() {
    return List.generate(_rivalFormation.length, (index) {
      final (x, y) = _rivalFormation[index];
      return MatchPlayerMarker(
        side: MatchTeamSide.rival,
        index: index,
        label: 'R${index + 1}',
        x: x,
        y: y,
      );
    });
  }

  static List<MatchPlayerMarker> userMarkersFromNames(List<String> names) {
    final markers = <MatchPlayerMarker>[];
    for (var i = 0; i < _userFormation.length; i++) {
      final (x, y) = _userFormation[i];
      final label = i < names.length ? names[i] : 'U${i + 1}';
      markers.add(
        MatchPlayerMarker(
          side: MatchTeamSide.user,
          index: i,
          label: label,
          x: x,
          y: y,
        ),
      );
    }
    return markers;
  }
}
