import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_local_datasource.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';

/// Repositorio read-only de equipos rivales Clash (Fase 42).
class ClashRivalsRepository {
  ClashRivalsRepository({ClashRivalsLocalDataSource? dataSource})
    : _dataSource = dataSource ?? ClashRivalsLocalDataSource();

  final ClashRivalsLocalDataSource _dataSource;

  Future<List<ClashRivalTeam>> fetchTeams() => _dataSource.loadRivals();

  Future<ClashRivalTeam?> findTeam(String id) async {
    final teams = await fetchTeams();
    for (final team in teams) {
      if (team.id == id) {
        return team;
      }
    }
    return null;
  }
}
