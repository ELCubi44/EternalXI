import 'package:eternal_xi/features/clash/match/data/clash_rival_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_player.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';

/// Resuelve plantilla rival para story/event match (Fase 42).
class ClashRivalMatchSetup {
  const ClashRivalMatchSetup({
    required this.squad,
    required this.rivalPower,
    this.rivalTeamName,
    this.difficulty,
  });

  final List<MatchSquadPlayer> squad;
  final int rivalPower;
  final String? rivalTeamName;
  final int? difficulty;
}

class ClashRivalMatchSetupResolver {
  const ClashRivalMatchSetupResolver._();

  static Future<ClashRivalMatchSetup> resolve({
    required ClashRivalsRepository repository,
    String? rivalTeamId,
    int? fallbackPower,
  }) async {
    final basePower = fallbackPower ?? 120;
    if (rivalTeamId == null || rivalTeamId.isEmpty) {
      return ClashRivalMatchSetup(
        squad: MatchSquadBuilder.buildRivalSquad(basePower: basePower),
        rivalPower: basePower,
      );
    }

    final team = await repository.findTeam(rivalTeamId);
    if (team == null) {
      return ClashRivalMatchSetup(
        squad: MatchSquadBuilder.buildRivalSquad(basePower: basePower),
        rivalPower: basePower,
      );
    }

    return ClashRivalMatchSetup(
      squad: ClashRivalSquadBuilder.buildSquadOrFallback(
        team: team,
        basePower: team.recommendedPower,
      ),
      rivalPower: team.recommendedPower,
      rivalTeamName: team.name,
      difficulty: team.difficulty,
    );
  }
}
