import 'package:eternal_xi/features/clash/shared/di/clash_providers.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_local_migration_runner.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ClashSharedPreferencesKeys', () {
    test('constants mantienen strings históricos', () {
      expect(ClashSharedPreferencesKeys.lineups7v7, 'clash_lineups_7v7_v1');
      expect(
        ClashSharedPreferencesKeys.playerCollectionV2,
        'clash_player_collection_v2',
      );
      expect(ClashSharedPreferencesKeys.gifts, 'clash_gifts_v1');
      expect(
        ClashSharedPreferencesKeys.storyProgress,
        'clash_story_progress_v1',
      );
    });

    test('no hay duplicates entre data keys', () {
      expect(
        ClashSharedPreferencesKeys.dataKeys.length,
        ClashSharedPreferencesKeys.dataKeys.toSet().length,
      );
    });

    test('schema keys no están en dataKeys', () {
      expect(
        ClashSharedPreferencesKeys.dataKeys.contains(
          ClashSharedPreferencesKeys.schemaVersion,
        ),
        isFalse,
      );
      expect(
        ClashSharedPreferencesKeys.dataKeys.contains(
          ClashSharedPreferencesKeys.lastMigratedAt,
        ),
        isFalse,
      );
    });
  });

  group('ClashLocalMigrationRunner', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('sin version corre migración 0→1', () async {
      final prefs = await SharedPreferences.getInstance();
      final result = await ClashLocalMigrationRunner(prefs).run();

      expect(result.fromVersion, 0);
      expect(result.toVersion, 1);
      expect(result.ranMigrations, ['0_to_1']);
      expect(result.skipped, isFalse);
      expect(result.isSuccess, isTrue);
      expect(prefs.getInt(ClashSharedPreferencesKeys.schemaVersion), 1);
      expect(
        prefs.getString(ClashSharedPreferencesKeys.lastMigratedAt),
        isNotNull,
      );
    });

    test('si ya está en 1 no corre migraciones', () async {
      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 1,
        ClashSharedPreferencesKeys.lastMigratedAt: '2026-01-01T00:00:00.000Z',
      });
      final prefs = await SharedPreferences.getInstance();
      final result = await ClashLocalMigrationRunner(prefs).run();

      expect(result.skipped, isTrue);
      expect(result.ranMigrations, isEmpty);
      expect(result.fromVersion, 1);
      expect(result.toVersion, 1);
    });

    test('no borra keys existentes', () async {
      const collectionJson = '{"ownedCardIds":["card-a"],"cardProgress":{}}';
      const giftsJson = '{"claimedGiftIds":["gift-a"]}';
      const lineupsJson = '{"slots":[]}';

      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.playerCollectionV2: collectionJson,
        ClashSharedPreferencesKeys.gifts: giftsJson,
        ClashSharedPreferencesKeys.lineups7v7: lineupsJson,
      });
      final prefs = await SharedPreferences.getInstance();
      await ClashLocalMigrationRunner(prefs).run();

      expect(
        prefs.getString(ClashSharedPreferencesKeys.playerCollectionV2),
        collectionJson,
      );
      expect(prefs.getString(ClashSharedPreferencesKeys.gifts), giftsJson);
      expect(
        prefs.getString(ClashSharedPreferencesKeys.lineups7v7),
        lineupsJson,
      );
    });

    test('versión futura se detecta sin bajar schema', () async {
      SharedPreferences.setMockInitialValues({
        ClashSharedPreferencesKeys.schemaVersion: 99,
      });
      final prefs = await SharedPreferences.getInstance();
      final result = await ClashLocalMigrationRunner(prefs).run();

      expect(result.skipped, isTrue);
      expect(result.futureVersionDetected, isTrue);
      expect(result.fromVersion, 99);
      expect(result.toVersion, 99);
      expect(result.ranMigrations, isEmpty);
      expect(prefs.getInt(ClashSharedPreferencesKeys.schemaVersion), 99);
    });
  });

  group('prepareClashProviders', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ejecuta migración al preparar providers', () async {
      final deps = await prepareClashProviders();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.getInt(ClashSharedPreferencesKeys.schemaVersion), 1);
      expect(deps.migrationResult?.migrated, isTrue);
      expect(
        deps.migrationResult?.toVersion,
        ClashStorageSchema.currentVersion,
      );
    });
  });
}
