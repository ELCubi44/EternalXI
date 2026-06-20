import 'package:eternal_xi/features/clash/sync/data/clash_claim_id_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClashClaimIdBuilder Fase 83', () {
    test('gift genera formato esperado', () {
      expect(ClashClaimIdBuilder.gift('gift-welcome'), 'gift:gift-welcome');
    });

    test('achievement genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.achievement('ach-first-win'),
        'achievement:ach-first-win',
      );
    });

    test('dailyMission usa fecha UTC estable', () {
      expect(
        ClashClaimIdBuilder.dailyMission(
          'daily-play-1',
          DateTime.utc(2026, 6, 20, 15, 30),
        ),
        'mission:daily:daily-play-1:2026-06-20',
      );
    });

    test('weeklyMission genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.weeklyMission('weekly-win-3', '2026-W25'),
        'mission:weekly:weekly-win-3:2026-W25',
      );
    });

    test('eventFirstClear genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.eventFirstClear('mika', 'stage-1'),
        'event:mika:stage-1:firstClear',
      );
    });

    test('eventRepeat genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.eventRepeat('mika', 'stage-1', 'attempt-2'),
        'event:mika:stage-1:repeat:attempt-2',
      );
    });

    test('shop genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.shop('pack-starter', 'buy-1'),
        'shop:pack-starter:buy-1',
      );
    });

    test('storyFirstClear genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.storyFirstClear('chapter-1', 'stage-2'),
        'story:chapter-1:stage-2:firstClear',
      );
    });

    test('storyObjective genera formato esperado', () {
      expect(
        ClashClaimIdBuilder.storyObjective('chapter-1', 'stage-2', 'obj-a'),
        'story:chapter-1:stage-2:objective:obj-a',
      );
    });

    test('strings vacíos lanzan ArgumentError', () {
      expect(() => ClashClaimIdBuilder.gift(' '), throwsArgumentError);
      expect(
        () => ClashClaimIdBuilder.dailyMission('', DateTime.utc(2026)),
        throwsArgumentError,
      );
    });

    test('formatos no contienen userId', () {
      final ids = [
        ClashClaimIdBuilder.gift('gift-a'),
        ClashClaimIdBuilder.dailyMission('m1', DateTime.utc(2026, 1, 2)),
      ];
      for (final id in ids) {
        expect(id.contains('userId'), isFalse);
        expect(id.contains('idUsuario'), isFalse);
      }
    });
  });
}
