import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/match/data/clash_rival_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:eternal_xi/features/clash/match/domain/match_team_side.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rival_match_setup_resolver.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_local_datasource.dart';
import 'package:eternal_xi/features/clash/rivals/data/clash_rivals_repository.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_player.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_power_comparison.dart';
import 'package:eternal_xi/features/clash/rivals/domain/clash_rival_team.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashRivalsRepository', () {
    test('carga rivals.json', () async {
      final teams = await ClashRivalsRepository().fetchTeams();
      expect(teams, hasLength(3));
      expect(
        teams.map((team) => team.id),
        containsAll([
          'rival-training-squad',
          'rival-arin-training',
          'rival-mika-speed',
        ]),
      );
    });

    test('cada equipo tiene lineup 7v7 completo', () async {
      final teams = await ClashRivalsRepository().fetchTeams();
      for (final team in teams) {
        expect(team.lineup7v7, hasLength(7));
        expect(team.hasCompleteLineup, isTrue);
        expect(team.requiredPositionsComplete, isTrue);
        final positions = team.lineup7v7.map((p) => p.position).toSet();
        expect(positions, ClashPosition.values.toSet());
      }
    });

    test('totalPower suma potencia de jugadores', () async {
      final team = await ClashRivalsRepository().findTeam(
        'rival-training-squad',
      );
      expect(team, isNotNull);
      final manual = team!.lineup7v7.fold<int>(
        0,
        (sum, player) => sum + player.power,
      );
      expect(team.totalPower, manual);
    });

    test('predominantStyles no está vacío en equipos reales', () async {
      final team = await ClashRivalsRepository().findTeam(
        'rival-arin-training',
      );
      expect(team!.predominantStyles, isNotEmpty);
    });

    test('dificultad 1 y 2 distinguen equipos de prueba', () async {
      final training = await ClashRivalsRepository().findTeam(
        'rival-training-squad',
      );
      final arin = await ClashRivalsRepository().findTeam(
        'rival-arin-training',
      );
      expect(training!.difficulty, 1);
      expect(arin!.difficulty, 2);
    });

    test('stats y técnicas parsean correctamente', () async {
      final team = await ClashRivalsRepository().findTeam(
        'rival-training-squad',
      );
      expect(team, isNotNull);
      final gk = team!.lineup7v7.firstWhere(
        (player) => player.position == ClashPosition.goalkeeper,
      );
      expect(gk.stats.save, greaterThan(0));
      expect(gk.superTechniques, isNotEmpty);
      expect(gk.superTechniques.first.type, ClashTechniqueType.save);
    });
  });

  group('ClashRivalPowerComparison', () {
    test('evalúa umbrales de preparación', () {
      expect(
        ClashRivalPowerComparison.evaluate(ownPower: 120, referencePower: 80),
        ClashRivalPowerMatchupStatus.clearAdvantage,
      );
      expect(
        ClashRivalPowerComparison.evaluate(ownPower: 70, referencePower: 80),
        ClashRivalPowerMatchupStatus.even,
      );
      expect(
        ClashRivalPowerComparison.evaluate(ownPower: 50, referencePower: 80),
        ClashRivalPowerMatchupStatus.disadvantage,
      );
      expect(
        ClashRivalPowerComparison.evaluate(ownPower: 30, referencePower: 80),
        ClashRivalPowerMatchupStatus.veryHard,
      );
    });
  });

  group('ClashRivalSquadBuilder', () {
    late ClashRivalTeam trainingTeam;

    setUp(() async {
      trainingTeam = (await ClashRivalsRepository().findTeam(
        'rival-training-squad',
      ))!;
    });

    test('construye squad 7v7', () {
      final squad = ClashRivalSquadBuilder.buildSquad(trainingTeam);
      expect(squad, hasLength(7));
      expect(
        squad.every((player) => player.side == MatchTeamSide.rival),
        isTrue,
      );
    });

    test('portero se identifica correctamente', () {
      final squad = ClashRivalSquadBuilder.buildSquad(trainingTeam);
      final gk = squad.firstWhere(
        (player) => player.position == ClashPosition.goalkeeper,
      );
      expect(gk.label, 'Portero');
      expect(gk.effectiveSave, greaterThan(0));
    });

    test('stats y técnicas llegan al motor', () {
      final squad = ClashRivalSquadBuilder.buildSquad(trainingTeam);
      final striker = squad.firstWhere(
        (player) => player.position == ClashPosition.striker,
      );
      expect(striker.power, greaterThan(0));
      expect(striker.superTechniques, isNotEmpty);
      expect(striker.superTechniques.first.type, ClashTechniqueType.shot);
    });

    test('lineup incompleta usa fallback genérico', () {
      final broken = ClashRivalTeam(
        id: 'broken',
        name: 'Roto',
        description: 'test',
        difficulty: 1,
        recommendedPower: 95,
        lineup7v7: [
          ClashRivalPlayer(
            id: 'only-gk',
            name: 'Solo Portero',
            position: ClashPosition.goalkeeper,
            style: trainingTeam.lineup7v7.first.style,
            level: 1,
            stats: trainingTeam.lineup7v7.first.stats,
          ),
        ],
      );

      expect(
        () => ClashRivalSquadBuilder.buildSquad(broken),
        throwsA(isA<ClashRivalSquadBuildException>()),
      );

      final fallback = ClashRivalSquadBuilder.buildSquadOrFallback(
        team: broken,
        basePower: 95,
      );
      final generic = MatchSquadBuilder.buildRivalSquad(basePower: 95);
      expect(fallback.length, generic.length);
      expect(fallback.first.label, generic.first.label);
    });
  });

  group('ClashRivalMatchSetupResolver', () {
    test('sin rivalTeamId mantiene fallback genérico', () async {
      final setup = await ClashRivalMatchSetupResolver.resolve(
        repository: ClashRivalsRepository(),
        fallbackPower: 120,
      );
      expect(setup.rivalTeamName, isNull);
      expect(setup.squad, hasLength(7));
      expect(setup.rivalPower, 120);
    });

    test('story rival usa Equipo de entrenamiento', () async {
      final setup = await ClashRivalMatchSetupResolver.resolve(
        repository: ClashRivalsRepository(),
        rivalTeamId: 'rival-training-squad',
        fallbackPower: 120,
      );
      expect(setup.rivalTeamName, 'Equipo de entrenamiento');
      expect(setup.rivalPower, 80);
      expect(
        setup.squad
            .firstWhere((player) => player.position == ClashPosition.goalkeeper)
            .label,
        'Portero',
      );
    });

    test('evento Arin usa Grupo de Arin', () async {
      final setup = await ClashRivalMatchSetupResolver.resolve(
        repository: ClashRivalsRepository(),
        rivalTeamId: 'rival-arin-training',
        fallbackPower: 85,
      );
      expect(setup.rivalTeamName, 'Grupo de Arin');
      expect(setup.difficulty, 2);
      expect(setup.rivalPower, 110);
    });

    test('evento Mika usa Equipo Relámpago de Mika', () async {
      final setup = await ClashRivalMatchSetupResolver.resolve(
        repository: ClashRivalsRepository(),
        rivalTeamId: 'rival-mika-speed',
        fallbackPower: 105,
      );
      expect(setup.rivalTeamName, 'Equipo Relámpago de Mika');
      expect(setup.difficulty, 2);
      expect(setup.rivalPower, 120);
    });
  });

  group('ClashRivalsLocalDataSource', () {
    test('parseRivalsJson rechaza JSON sin rivals', () {
      expect(
        () => ClashRivalsLocalDataSource().parseRivalsJson('{}'),
        throwsFormatException,
      );
    });
  });
}
