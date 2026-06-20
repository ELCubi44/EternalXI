import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persiste ajustes locales de sync (Fase 79–80).
class ClashSyncSettingsStorage {
  const ClashSyncSettingsStorage({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  static const storageKey = ClashSharedPreferencesKeys.syncAutoCheckEnabled;
  static const dismissedPendingRevisionKey =
      ClashSharedPreferencesKeys.syncPendingNoticeDismissedRevision;

  ClashSyncSettings load() {
    return ClashSyncSettings(
      autoCheckEnabledOnClashOpen:
          sharedPreferences.getBool(storageKey) ?? false,
    );
  }

  Future<bool> setAutoCheckEnabledOnClashOpen(bool enabled) async {
    return sharedPreferences.setBool(storageKey, enabled);
  }

  int? loadDismissedPendingRevision() {
    return sharedPreferences.getInt(dismissedPendingRevisionKey);
  }

  Future<bool> dismissPendingRevision(int revision) async {
    return sharedPreferences.setInt(dismissedPendingRevisionKey, revision);
  }

  Future<bool> clearDismissedPendingRevision() async {
    return sharedPreferences.remove(dismissedPendingRevisionKey);
  }
}
