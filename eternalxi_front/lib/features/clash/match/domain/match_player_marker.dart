import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Marcador de jugador en el minicampo (coordenadas normalizadas 0–1).
class MatchPlayerMarker {
  const MatchPlayerMarker({
    required this.side,
    required this.index,
    required this.label,
    required this.x,
    required this.y,
    this.cardId,
  });

  final MatchTeamSide side;
  final int index;
  final String label;
  final String? cardId;
  final double x;
  final double y;
}
