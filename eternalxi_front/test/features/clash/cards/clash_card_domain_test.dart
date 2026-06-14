import 'package:eternal_xi/features/clash/cards/domain/clash_card.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_card_progress.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_stats.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_super_technique.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_team_power.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:flutter_test/flutter_test.dart';

ClashStats _stats({
  int save = 10,
  int defense = 10,
  int pass = 10,
  int dribble = 10,
  int shot = 10,
  int techniquePoints = 10,
  int stamina = 100,
}) {
  return ClashStats(
    save: save,
    defense: defense,
    pass: pass,
    dribble: dribble,
    shot: shot,
    techniquePoints: techniquePoints,
    stamina: stamina,
  );
}

ClashSuperTechnique _technique({
  String id = 'tech-1',
  int basePower = 50,
  int ptCost = 10,
  ClashTechniqueLevel level = ClashTechniqueLevel.normal,
}) {
  return ClashSuperTechnique(
    id: id,
    name: 'Técnica $id',
    description: 'Descripción',
    type: ClashTechniqueType.shot,
    style: ClashPlayerStyle.potente,
    basePower: basePower,
    ptCost: ptCost,
    level: level,
  );
}

ClashCard _card({
  String id = 'card-1',
  int playerId = 42,
  ClashRarity rarity = ClashRarity.n,
  int level = 1,
  List<ClashSuperTechnique>? superTechniques,
  String? passiveId,
  ClashStats? stats,
}) {
  return ClashCard(
    id: id,
    playerId: playerId,
    rarity: rarity,
    level: level,
    style: ClashPlayerStyle.valiente,
    position: ClashPosition.striker,
    stats: stats ?? _stats(),
    superTechniques: superTechniques ?? [_technique()],
    basicPortraitPath: '/assets/clash/portrait.png',
    passiveId: passiveId,
  );
}

void main() {
  group('ClashRarity', () {
    test('niveles máximos por rareza', () {
      expect(ClashRarity.n.maxLevel, 60);
      expect(ClashRarity.r.maxLevel, 80);
      expect(ClashRarity.sr.maxLevel, 100);
      expect(ClashRarity.lr.maxLevel, 120);
      expect(ClashRarity.xi.maxLevel, 120);
    });

    test('cantidad de supertécnicas por rareza', () {
      expect(ClashRarity.n.maxSuperTechniques, 1);
      expect(ClashRarity.r.maxSuperTechniques, 2);
      expect(ClashRarity.sr.maxSuperTechniques, 3);
      expect(ClashRarity.lr.maxSuperTechniques, 4);
      expect(ClashRarity.xi.maxSuperTechniques, 4);
    });

    test('evolución permitida y prohibida', () {
      expect(ClashRarity.n.canEvolveTo(ClashRarity.r), isTrue);
      expect(ClashRarity.n.canEvolveTo(ClashRarity.sr), isTrue);
      expect(ClashRarity.n.canEvolveTo(ClashRarity.lr), isFalse);
      expect(ClashRarity.n.canEvolveTo(ClashRarity.xi), isFalse);

      expect(ClashRarity.r.canEvolveTo(ClashRarity.sr), isTrue);
      expect(ClashRarity.r.canEvolveTo(ClashRarity.n), isFalse);

      expect(ClashRarity.sr.canEvolveTo(ClashRarity.lr), isFalse);
      expect(ClashRarity.lr.canEvolveTo(ClashRarity.sr), isFalse);
      expect(ClashRarity.xi.canEvolveTo(ClashRarity.sr), isFalse);
    });

    test('LR y XI no se obtienen por evolución', () {
      expect(ClashRarity.lr.obtainableByEvolution, isFalse);
      expect(ClashRarity.xi.obtainableByEvolution, isFalse);
      expect(ClashRarity.r.obtainableByEvolution, isTrue);
      expect(ClashRarity.sr.obtainableByEvolution, isTrue);
    });

    test('solo XI permite pasiva', () {
      expect(ClashRarity.xi.allowsPassive, isTrue);
      for (final rarity in ClashRarity.values) {
        if (rarity != ClashRarity.xi) {
          expect(rarity.allowsPassive, isFalse);
        }
      }
    });
  });

  group('ClashPlayerStyle rueda', () {
    test('ventaja directa en la rueda', () {
      expect(
        compareClashStyles(ClashPlayerStyle.picaro, ClashPlayerStyle.potente),
        ClashStyleMatchup.advantage,
      );
      expect(
        compareClashStyles(ClashPlayerStyle.potente, ClashPlayerStyle.valiente),
        ClashStyleMatchup.advantage,
      );
      expect(
        compareClashStyles(ClashPlayerStyle.valiente, ClashPlayerStyle.preciso),
        ClashStyleMatchup.advantage,
      );
      expect(
        compareClashStyles(ClashPlayerStyle.preciso, ClashPlayerStyle.agil),
        ClashStyleMatchup.advantage,
      );
      expect(
        compareClashStyles(ClashPlayerStyle.agil, ClashPlayerStyle.picaro),
        ClashStyleMatchup.advantage,
      );
    });

    test('desventaja inversa en la rueda', () {
      expect(
        compareClashStyles(ClashPlayerStyle.potente, ClashPlayerStyle.picaro),
        ClashStyleMatchup.disadvantage,
      );
      expect(
        compareClashStyles(ClashPlayerStyle.valiente, ClashPlayerStyle.potente),
        ClashStyleMatchup.disadvantage,
      );
    });

    test('neutral consigo mismo', () {
      for (final style in ClashPlayerStyle.values) {
        expect(compareClashStyles(style, style), ClashStyleMatchup.neutral);
      }
    });
  });

  group('ClashStats', () {
    test('potencia igual a suma de estadísticas', () {
      final stats = _stats(
        save: 12,
        defense: 15,
        pass: 20,
        dribble: 18,
        shot: 22,
        techniquePoints: 30,
        stamina: 110,
      );
      expect(stats.power, 12 + 15 + 20 + 18 + 22 + 30 + 110);
    });

    test('no acepta valores negativos', () {
      expect(() => _stats(save: -1), throwsA(isA<AssertionError>()));
    });

    test('sin penalización con resistencia >= 100', () {
      expect(ClashStats.staminaPerformanceMultiplier(100), 1.0);
      expect(ClashStats.staminaPerformanceMultiplier(130), 1.0);

      final stats = _stats(save: 80);
      expect(stats.effectiveSave(100), 80);
      expect(stats.effectiveSave(120), 80);
    });

    test('penalización por debajo de 100 de resistencia', () {
      final stats = _stats(save: 100);
      final multiplier = ClashStats.staminaPerformanceMultiplier(50);
      expect(multiplier, lessThan(1.0));
      expect(stats.effectiveSave(50), (100 * multiplier).round());
    });

    test('mínimo del multiplicador de cansancio es 0.70', () {
      expect(ClashStats.staminaPerformanceMultiplier(0), 0.70);
      expect(ClashStats.staminaPerformanceMultiplier(-50), 0.70);
    });

    test('PT no afectado por cansancio', () {
      final stats = _stats(techniquePoints: 45);
      expect(stats.effectiveTechniquePoints(100), 45);
      expect(stats.effectiveTechniquePoints(50), 45);
      expect(stats.effectiveTechniquePoints(0), 45);
    });
  });

  group('ClashSuperTechnique', () {
    test('niveles aumentan potencia efectiva', () {
      const base = 100;
      final normal = _technique(
        basePower: base,
        level: ClashTechniqueLevel.normal,
      );
      final xi = _technique(basePower: base, level: ClashTechniqueLevel.xi);

      expect(normal.effectivePower, 100);
      expect(xi.effectivePower, 120);
      expect(xi.effectivePower, greaterThan(normal.effectivePower));
    });

    test('nivel de técnica no reduce ptCost', () {
      final normal = _technique(ptCost: 15, level: ClashTechniqueLevel.normal);
      final xi = _technique(ptCost: 15, level: ClashTechniqueLevel.xi);

      expect(normal.ptCost, 15);
      expect(xi.ptCost, 15);
    });

    test('canBeUsed según PT disponibles', () {
      final technique = _technique(ptCost: 20);
      expect(technique.canBeUsed(20), isTrue);
      expect(technique.canBeUsed(25), isTrue);
      expect(technique.canBeUsed(19), isFalse);
    });
  });

  group('ClashCard validación', () {
    test('validación de cantidad de técnicas por rareza', () {
      expect(
        () => ClashCard.validate(
          rarity: ClashRarity.n,
          level: 1,
          superTechniques: [
            _technique(),
            _technique(id: 'tech-2'),
          ],
          passiveId: null,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => ClashCard.validate(
          rarity: ClashRarity.r,
          level: 1,
          superTechniques: [
            _technique(id: 'a'),
            _technique(id: 'b'),
            _technique(id: 'c'),
          ],
          passiveId: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pasiva permitida únicamente en XI', () {
      expect(
        () => ClashCard.validate(
          rarity: ClashRarity.sr,
          level: 1,
          superTechniques: [_technique()],
          passiveId: 'passive-1',
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => ClashCard.validate(
          rarity: ClashRarity.xi,
          level: 1,
          superTechniques: [_technique()],
          passiveId: 'passive-1',
        ),
        returnsNormally,
      );
    });

    test('nivel fuera de rango rechazado', () {
      expect(
        () => ClashCard.validate(
          rarity: ClashRarity.n,
          level: 61,
          superTechniques: [_technique()],
          passiveId: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('ClashCardProgress', () {
    test('máximo de 5 nodos duplicados', () {
      const progress = ClashCardProgress(
        cardId: 'card-1',
        currentLevel: 10,
        currentExperience: 0,
        unlockedDuplicateNodes: 5,
        techniqueLevels: {},
      );
      expect(progress.isTreeMaximized, isTrue);
      expect(() => progress.validateForRarity(ClashRarity.sr), returnsNormally);

      const tooMany = ClashCardProgress(
        cardId: 'card-1',
        currentLevel: 10,
        currentExperience: 0,
        unlockedDuplicateNodes: 6,
        techniqueLevels: {},
      );
      expect(
        () => tooMany.validateForRarity(ClashRarity.sr),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('N y R sin árbol de duplicados', () {
      const progress = ClashCardProgress(
        cardId: 'card-1',
        currentLevel: 5,
        currentExperience: 100,
        unlockedDuplicateNodes: 1,
        techniqueLevels: {},
      );

      expect(ClashRarity.n.hasDuplicateTree, isFalse);
      expect(ClashRarity.r.hasDuplicateTree, isFalse);
      expect(
        () => progress.validateForRarity(ClashRarity.n),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => progress.validateForRarity(ClashRarity.r),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('SR LR XI permiten árbol', () {
      const progress = ClashCardProgress(
        cardId: 'card-1',
        currentLevel: 10,
        currentExperience: 0,
        unlockedDuplicateNodes: 3,
        techniqueLevels: {'tech-1': ClashTechniqueLevel.v},
      );

      for (final rarity in [ClashRarity.sr, ClashRarity.lr, ClashRarity.xi]) {
        expect(() => progress.validateForRarity(rarity), returnsNormally);
      }
    });
  });

  group('Potencia de equipo', () {
    test('suma potencia de cartas', () {
      final cards = [
        _card(id: 'a', stats: _stats(save: 10, defense: 10)),
        _card(id: 'b', stats: _stats(save: 20, defense: 20)),
      ];
      expect(calculateClashTeamPower(cards), cards[0].power + cards[1].power);
    });
  });

  group('Serialización round-trip', () {
    test('ClashStats', () {
      final original = _stats(stamina: 105);
      final restored = ClashStats.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
      expect(restored.power, original.power);
    });

    test('ClashSuperTechnique', () {
      final original = _technique(
        id: 'st-99',
        level: ClashTechniqueLevel.x,
        ptCost: 25,
      );
      final restored = ClashSuperTechnique.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
      expect(restored.effectivePower, original.effectivePower);
    });

    test('ClashCard', () {
      final original = _card(
        rarity: ClashRarity.xi,
        level: 50,
        passiveId: 'passive-xi',
        superTechniques: [
          _technique(id: 't1'),
          _technique(id: 't2'),
          _technique(id: 't3'),
          _technique(id: 't4'),
        ],
        stats: _stats(stamina: 130),
      );
      final json = original.toJson();
      final restored = ClashCard.fromJson(json);
      expect(restored.toJson(), json);
      expect(restored.playerId, 42);
      expect(restored.passiveId, 'passive-xi');
    });

    test('ClashCardProgress', () {
      const original = ClashCardProgress(
        cardId: 'card-abc',
        currentLevel: 25,
        currentExperience: 1500,
        unlockedDuplicateNodes: 2,
        techniqueLevels: {
          'tech-1': ClashTechniqueLevel.i,
          'tech-2': ClashTechniqueLevel.v,
        },
      );
      final restored = ClashCardProgress.fromJson(original.toJson());
      expect(restored.toJson(), original.toJson());
    });

    test('ClashCard.fromJson tolera numéricos como double', () {
      final json = _card(playerId: 7).toJson();
      json['playerId'] = 7.0;
      json['level'] = 1.0;
      final restored = ClashCard.fromJson(json);
      expect(restored.playerId, 7);
      expect(restored.level, 1);
    });
  });

  group('ClashPosition nombres', () {
    test('displayNameEs en español', () {
      expect(ClashPosition.goalkeeper.displayNameEs, 'Portero');
      expect(ClashPosition.striker.displayNameEs, 'Delantero');
    });
  });
}
