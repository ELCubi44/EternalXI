import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/shared/migrations/domain/clash_storage_schema.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Migraciones locales secuenciales de Clash (Fase 56).
abstract final class ClashLocalMigrations {
  static const migration0To1Id = '0_to_1';

  /// Registra schema v1 sin transformar datos existentes.
  static Future<void> migrate0To1(SharedPreferences prefs) async {
    final dataKeysPresent = prefs
        .getKeys()
        .where(ClashSharedPreferencesKeys.dataKeys.contains)
        .toSet();
    final stringSnapshots = <String, String?>{
      for (final key in dataKeysPresent) key: prefs.getString(key),
    };

    await prefs.setInt(
      ClashSharedPreferencesKeys.schemaVersion,
      ClashStorageSchema.currentVersion,
    );
    await prefs.setString(
      ClashSharedPreferencesKeys.lastMigratedAt,
      DateTime.now().toUtc().toIso8601String(),
    );

    for (final key in dataKeysPresent) {
      if (!prefs.containsKey(key)) {
        throw StateError('Clash migration 0→1 perdió la clave: $key');
      }
      if (prefs.getString(key) != stringSnapshots[key]) {
        throw StateError('Clash migration 0→1 alteró la clave: $key');
      }
    }

    if (kDebugMode) {
      debugPrint(
        'ClashLocalMigrations: $migration0To1Id completada '
        '(schema=${ClashStorageSchema.currentVersion})',
      );
    }
  }
}
