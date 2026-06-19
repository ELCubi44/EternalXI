import 'package:eternal_xi/features/clash/shared/migrations/data/clash_local_migration.dart';
import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_migration_result.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ejecuta migraciones pendientes del esquema local Clash (Fase 56).
class ClashLocalMigrationRunner {
  ClashLocalMigrationRunner(this._prefs);

  final SharedPreferences _prefs;

  int readStoredVersion() {
    return _prefs.getInt(ClashSharedPreferencesKeys.schemaVersion) ??
        ClashStorageSchema.legacyUntrackedVersion;
  }

  Future<ClashMigrationResult> run() async {
    final fromVersion = readStoredVersion();

    if (fromVersion > ClashStorageSchema.currentVersion) {
      return ClashMigrationResult(
        fromVersion: fromVersion,
        toVersion: fromVersion,
        skipped: true,
        futureVersionDetected: true,
      );
    }

    if (fromVersion >= ClashStorageSchema.currentVersion) {
      return ClashMigrationResult(
        fromVersion: fromVersion,
        toVersion: fromVersion,
        skipped: true,
      );
    }

    final ran = <String>[];
    var version = fromVersion;

    try {
      while (version < ClashStorageSchema.currentVersion) {
        switch (version) {
          case 0:
            await ClashLocalMigrations.migrate0To1(_prefs);
            ran.add(ClashLocalMigrations.migration0To1Id);
            version = 1;
          default:
            throw StateError(
              'Migración Clash no definida para versión $version',
            );
        }
      }

      return ClashMigrationResult(
        fromVersion: fromVersion,
        toVersion: version,
        ranMigrations: ran,
      );
    } catch (error) {
      return ClashMigrationResult(
        fromVersion: fromVersion,
        toVersion: version,
        ranMigrations: ran,
        errors: [error.toString()],
      );
    }
  }
}
