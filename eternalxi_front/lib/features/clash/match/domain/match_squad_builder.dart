import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/data/models/clash_card_catalog_entry.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/domain/match_pitch_layout.dart';
import 'package:eternal_xi/features/clash/match/domain/match_player_marker.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/team/domain/clash_lineup_7v7.dart';

/// Construye plantillas de partido a partir de alineación y catálogo.
class MatchSquadBuilder {
  const MatchSquadBuilder._();

  static List<MatchSquadPlayer> buildUserSquad({
    required ClashLineup7v7? lineup,
    required Map<String, ClashCardCatalogEntry> catalogById,
  }) {
    final players = <MatchSquadPlayer>[];
    for (var i = 0; i < ClashPosition.values.length; i++) {
      final position = ClashPosition.values[i];
      final (x, y) = MatchPitchLayout.coordsForIndex(i, MatchTeamSide.user);
      final cardId = lineup?.cardIdFor(position);
      final entry = cardId != null ? catalogById[cardId] : null;

      if (entry != null) {
        players.add(
          MatchSquadPlayer(
            index: i,
            side: MatchTeamSide.user,
            cardId: entry.id,
            playerId: entry.playerId,
            position: entry.card.position,
            label: _shortLabel(entry.name),
            homeX: x,
            homeY: y,
            baseStats: entry.displayStats,
            power: entry.power,
            currentStamina: entry.card.stats.stamina,
            style: entry.card.style,
            superTechniques: entry.card.superTechniques,
            maxPt: entry.card.stats.techniquePoints,
            currentPt: entry.card.stats.techniquePoints,
          ),
        );
      } else {
        players.add(_placeholderPlayer(i, MatchTeamSide.user, x, y));
      }
    }
    return players;
  }

  static List<MatchSquadPlayer> buildRivalSquad({int basePower = 120}) {
    final perStat = (basePower / 7).round().clamp(8, 40);
    final players = <MatchSquadPlayer>[];
    for (var i = 0; i < ClashPosition.values.length; i++) {
      final position = ClashPosition.values[i];
      final (x, y) = MatchPitchLayout.coordsForIndex(i, MatchTeamSide.rival);
      final stats = ClashStats(
        save: perStat,
        defense: perStat + 2,
        pass: perStat,
        dribble: perStat,
        shot: perStat,
        techniquePoints: 10,
        stamina: 100,
      );
      final techniques = _rivalTechniquesFor(position, i);
      players.add(
        MatchSquadPlayer(
          index: i,
          side: MatchTeamSide.rival,
          cardId: 'rival-$i',
          playerId: 9000 + i,
          position: position,
          label: 'R${i + 1}',
          homeX: x,
          homeY: y,
          baseStats: stats,
          power: stats.power,
          currentStamina: stats.stamina,
          style: ClashPlayerStyle.values[i % ClashPlayerStyle.values.length],
          superTechniques: techniques,
          maxPt: stats.techniquePoints,
          currentPt: stats.techniquePoints,
        ),
      );
    }
    return players;
  }

  static List<MatchPlayerMarker> markersFromSquad(
    List<MatchSquadPlayer> squad,
  ) {
    return squad
        .map(
          (player) => MatchPlayerMarker(
            side: player.side,
            index: player.index,
            label: player.label,
            x: player.homeX,
            y: player.homeY,
            cardId: player.cardId,
          ),
        )
        .toList();
  }

  static MatchSquadPlayer _placeholderPlayer(
    int index,
    MatchTeamSide side,
    double x,
    double y,
  ) {
    final stats = const ClashStats(
      save: 20,
      defense: 20,
      pass: 20,
      dribble: 20,
      shot: 20,
      techniquePoints: 10,
      stamina: 100,
    );
    return MatchSquadPlayer(
      index: index,
      side: side,
      cardId: 'placeholder-$index',
      playerId: 8000 + index,
      position: ClashPosition.values[index],
      label: side == MatchTeamSide.user ? 'U${index + 1}' : 'R${index + 1}',
      homeX: x,
      homeY: y,
      baseStats: stats,
      power: stats.power,
      currentStamina: stats.stamina,
      style: ClashPlayerStyle.valiente,
      superTechniques: const [],
      maxPt: stats.techniquePoints,
      currentPt: stats.techniquePoints,
    );
  }

  static List<ClashSuperTechnique> _rivalTechniquesFor(
    ClashPosition position,
    int index,
  ) {
    final type = switch (position) {
      ClashPosition.goalkeeper => ClashTechniqueType.save,
      ClashPosition.centreBack ||
      ClashPosition.fullBack => ClashTechniqueType.defense,
      ClashPosition.defensiveMidfielder => ClashTechniqueType.defense,
      ClashPosition.attackingMidfielder => ClashTechniqueType.dribble,
      ClashPosition.winger => ClashTechniqueType.dribble,
      ClashPosition.striker => ClashTechniqueType.shot,
    };
    return [
      ClashSuperTechnique(
        id: 'rival-$index-st1',
        name: 'Técnica R${index + 1}',
        description: 'Supertécnica rival provisional.',
        type: type,
        style: ClashPlayerStyle.values[index % ClashPlayerStyle.values.length],
        basePower: 36,
        ptCost: 10,
        level: ClashTechniqueLevel.normal,
      ),
    ];
  }

  static String _shortLabel(String name) {
    if (name.length <= 8) {
      return name;
    }
    return name.split(' ').first;
  }
}
