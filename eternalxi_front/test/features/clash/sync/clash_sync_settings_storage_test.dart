import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/data/clash_sync_settings_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ClashSyncSettingsStorage Fase 79', () {
    late SharedPreferences prefs;
    late ClashSyncSettingsStorage storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = ClashSyncSettingsStorage(sharedPreferences: prefs);
    });

    test('default auto-check desactivado', () {
      expect(storage.load().autoCheckEnabledOnClashOpen, isFalse);
    });

    test('guardar true persiste flag', () async {
      await storage.setAutoCheckEnabledOnClashOpen(true);

      expect(prefs.getBool(ClashSyncSettingsStorage.storageKey), isTrue);
      expect(storage.load().autoCheckEnabledOnClashOpen, isTrue);
    });

    test('guardar false persiste flag', () async {
      await storage.setAutoCheckEnabledOnClashOpen(true);
      await storage.setAutoCheckEnabledOnClashOpen(false);

      expect(storage.load().autoCheckEnabledOnClashOpen, isFalse);
    });

    test('storageKey no está en dataKeys', () {
      expect(
        ClashSharedPreferencesKeys.dataKeys,
        isNot(contains(ClashSyncSettingsStorage.storageKey)),
      );
    });

    test('dismissed revision null por defecto', () {
      expect(storage.loadDismissedPendingRevision(), isNull);
    });

    test('dismissPendingRevision persiste revision', () async {
      await storage.dismissPendingRevision(4);

      expect(
        prefs.getInt(ClashSyncSettingsStorage.dismissedPendingRevisionKey),
        4,
      );
      expect(storage.loadDismissedPendingRevision(), 4);
    });

    test('clearDismissedPendingRevision elimina key', () async {
      await storage.dismissPendingRevision(4);
      await storage.clearDismissedPendingRevision();

      expect(storage.loadDismissedPendingRevision(), isNull);
    });

    test('dismissedPendingRevisionKey no está en dataKeys', () {
      expect(
        ClashSharedPreferencesKeys.dataKeys,
        isNot(contains(ClashSyncSettingsStorage.dismissedPendingRevisionKey)),
      );
    });
  });
}
