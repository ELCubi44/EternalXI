import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/match/domain/clash_duel_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_ball_zone.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';

/// Un momento clave dentro de un partido resumido (sin minicampo).
class ClashDecisiveMoment {
  const ClashDecisiveMoment({
    required this.index,
    required this.minute,
    required this.title,
    required this.context,
    required this.duelType,
    required this.attackerSide,
    required this.ballZone,
    this.preferredPositions = const [],
  });

  final int index;
  final int minute;
  final String title;
  final String context;
  final ClashDuelType duelType;
  final MatchTeamSide attackerSide;
  final MatchBallZone ballZone;
  final List<ClashPosition> preferredPositions;

  bool get isUserAttacking => attackerSide == MatchTeamSide.user;

  bool get canScore => duelType == ClashDuelType.shotVsSave;
}

/// Guion por defecto: 5 momentos con alternancia ataque/defensa.
class ClashDecisiveMomentScript {
  const ClashDecisiveMomentScript._();

  static const List<ClashDecisiveMoment> defaultMoments = [
    ClashDecisiveMoment(
      index: 0,
      minute: 12,
      title: 'Salida r�pida',
      context: 'Robo en mediocampo. Tu equipo encara con espacio.',
      duelType: ClashDuelType.dribbleVsDefense,
      attackerSide: MatchTeamSide.user,
      ballZone: MatchBallZone.ownMidfield,
      preferredPositions: [
        ClashPosition.winger,
        ClashPosition.attackingMidfielder,
        ClashPosition.striker,
      ],
    ),
    ClashDecisiveMoment(
      index: 1,
      minute: 34,
      title: 'Contra del rival',
      context: 'Pierdes el bal�n arriba. El rival sale al ataque.',
      duelType: ClashDuelType.dribbleVsDefense,
      attackerSide: MatchTeamSide.rival,
      ballZone: MatchBallZone.rivalMidfield,
      preferredPositions: [
        ClashPosition.centreBack,
        ClashPosition.fullBack,
        ClashPosition.defensiveMidfielder,
      ],
    ),
    ClashDecisiveMoment(
      index: 2,
      minute: 52,
      title: 'Remate desde fuera',
      context: 'La jugada llega al borde del �rea. �Disparo?',
      duelType: ClashDuelType.shotVsSave,
      attackerSide: MatchTeamSide.user,
      ballZone: MatchBallZone.rivalMidfield,
      preferredPositions: [
        ClashPosition.striker,
        ClashPosition.attackingMidfielder,
        ClashPosition.winger,
      ],
    ),
    ClashDecisiveMoment(
      index: 3,
      minute: 71,
      title: 'Mano a mano',
      context: 'Filtraron un pase. El delantero rival se planta solo.',
      duelType: ClashDuelType.shotVsSave,
      attackerSide: MatchTeamSide.rival,
      ballZone: MatchBallZone.rivalArea,
      preferredPositions: [ClashPosition.goalkeeper],
    ),
    ClashDecisiveMoment(
      index: 4,
      minute: 89,
      title: '�ltima jugada',
      context: 'Empate tens o. Bal�n colgado al �rea. Todo o nada.',
      duelType: ClashDuelType.shotVsSave,
      attackerSide: MatchTeamSide.user,
      ballZone: MatchBallZone.rivalArea,
      preferredPositions: [
        ClashPosition.striker,
        ClashPosition.winger,
        ClashPosition.attackingMidfielder,
      ],
    ),
  ];
}
