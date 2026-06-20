import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClashRewardHistoryStorage Fase 60', () {
    test('guarda y carga entradas', () async {
      final backend = InMemoryClashRewardHistoryBackend();
      final entry = ClashRewardHistoryEntry.fromGrant(
        id: 'crh_1',
        sourceType: ClashRewardHistorySourceType.gift,
        sourceId: 'gift-1',
        title: 'Recompensa recibida',
        result: ClashRewardGrantResult(
          grantedRewards: [ClashReward.coins(100)],
          coinsAdded: 100,
        ),
        createdAt: DateTime.utc(2026, 6, 11, 12),
      );

      await backend.appendEntry(entry);
      final loaded = backend.readEntries();

      expect(loaded, hasLength(1));
      expect(loaded.first.id, 'crh_1');
      expect(loaded.first.rewards, hasLength(1));
      expect(loaded.first.rewards.first.amount, 100);
    });

    test('recorta a 100 entradas', () async {
      final backend = InMemoryClashRewardHistoryBackend();
      for (var i = 0; i < 105; i++) {
        await backend.appendEntry(
          ClashRewardHistoryEntry.fromGrant(
            id: 'crh_$i',
            sourceType: ClashRewardHistorySourceType.shop,
            title: 'Compra $i',
            result: ClashRewardGrantResult(
              grantedRewards: [ClashReward.gems(1)],
            ),
            createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
          ),
        );
      }

      expect(backend.readEntries(), hasLength(100));
    });

    test('preserva orden reciente primero', () async {
      final backend = InMemoryClashRewardHistoryBackend();
      await backend.appendEntry(
        ClashRewardHistoryEntry.fromGrant(
          id: 'old',
          sourceType: ClashRewardHistorySourceType.gift,
          title: 'Antigua',
          result: const ClashRewardGrantResult(),
          createdAt: DateTime.utc(2026, 1, 1),
        ),
      );
      await backend.appendEntry(
        ClashRewardHistoryEntry.fromGrant(
          id: 'new',
          sourceType: ClashRewardHistorySourceType.gift,
          title: 'Nueva',
          result: const ClashRewardGrantResult(),
          createdAt: DateTime.utc(2026, 6, 11),
        ),
      );

      final loaded = backend.readEntries();
      expect(loaded.first.id, 'new');
      expect(loaded.last.id, 'old');
    });

    test('serializa y deserializa rewards y failedRewards', () {
      final entry = ClashRewardHistoryEntry.fromGrant(
        id: 'crh_json',
        sourceType: ClashRewardHistorySourceType.event,
        sourceId: 'mika:stage-1',
        title: 'Primera victoria',
        result: ClashRewardGrantResult(
          grantedRewards: [
            ClashReward.gems(2),
            ClashReward.cardMissing('card-a'),
          ],
          failedRewards: [
            ClashFailedReward(
              reward: ClashReward.coins(50),
              error: 'grant_failed',
            ),
          ],
          newlyGrantedCardIds: ['card-a'],
          duplicateCardIds: ['card-b'],
        ),
        createdAt: DateTime.utc(2026, 6, 11, 10, 30),
      );

      final decoded = ClashRewardHistoryEntry.fromJson(entry.toJson());

      expect(decoded.rewards, hasLength(2));
      expect(decoded.failedRewards, hasLength(1));
      expect(decoded.isPartial, isTrue);
      expect(decoded.newlyGrantedCardIds, ['card-a']);
      expect(decoded.duplicateCardIds, ['card-b']);
    });

    test('key nueva está registrada sin colisiones', () {
      expect(
        ClashSharedPreferencesKeys.rewardHistory,
        'clash_reward_history_v1',
      );
      expect(
        ClashSharedPreferencesKeys.dataKeys,
        contains(ClashSharedPreferencesKeys.rewardHistory),
      );
      expect(
        ClashSharedPreferencesKeys.rewardHistory,
        isNot(equals(ClashSharedPreferencesKeys.gachaHistory)),
      );
    });
  });
}
