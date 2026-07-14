import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moment.dart';
import 'package:eternal_xi/features/clash/decisive_moments/domain/clash_decisive_moments_engine.dart';
import 'package:eternal_xi/features/clash/match/domain/match_chance_resolver.dart';
import 'package:eternal_xi/features/clash/match/domain/match_score.dart';
import 'package:eternal_xi/features/clash/match/domain/match_squad_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default script has five alternating moments', () {
    expect(ClashDecisiveMomentScript.defaultMoments, hasLength(5));
    expect(
      ClashDecisiveMomentScript.defaultMoments.first.isUserAttacking,
      isTrue,
    );
  });

  test('shot duel resolves with duel type from moment', () {
    const chance = FixedMatchChanceResolver(alwaysSucceed: true);
    final user = MatchSquadBuilder.buildUserSquad(
      lineup: null,
      catalogById: const {},
    );
    final rival = MatchSquadBuilder.buildRivalSquad(basePower: 50);
    final moment = ClashDecisiveMomentScript.defaultMoments[2];

    final attacker = user.reduce(
      (a, b) => a.effectiveShot >= b.effectiveShot ? a : b,
    );
    final defender = ClashDecisiveMomentsEngine.pickRivalDefender(
      rivalSquad: rival,
      moment: moment,
    );

    final resolution = ClashDecisiveMomentsEngine.resolve(
      moment: moment,
      attacker: attacker,
      defender: defender,
      score: const MatchScore(),
      chance: chance,
    );

    expect(resolution.duelType, moment.duelType);
  });
}
