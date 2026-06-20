import 'dart:convert';

import 'package:eternal_xi/features/clash/shared/migrations/data/clash_shared_preferences_keys.dart';
import 'package:eternal_xi/features/clash/sync/domain/clash_sync_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copia de seguridad local previa a aplicar snapshot remoto (Fase 73).
class ClashSyncLocalBackup {
  const ClashSyncLocalBackup({
    required this.generatedAt,
    required this.source,
    required this.snapshot,
    this.serverRevision,
  });

  static const sourceBeforeRemoteApply = 'beforeRemoteApply';

  final DateTime generatedAt;
  final String source;
  final ClashSyncSnapshot snapshot;
  final int? serverRevision;

  Map<String, dynamic> toJson() => {
    'generatedAt': generatedAt.toUtc().toIso8601String(),
    'source': source,
    if (serverRevision != null) 'serverRevision': serverRevision,
    'snapshot': snapshot.toJson(),
  };

  factory ClashSyncLocalBackup.fromJson(Map<String, dynamic> json) {
    final snapshotRaw = json['snapshot'];
    return ClashSyncLocalBackup(
      generatedAt:
          DateTime.tryParse(json['generatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      source: json['source']?.toString() ?? sourceBeforeRemoteApply,
      serverRevision: _readOptionalInt(json['serverRevision']),
      snapshot: snapshotRaw is Map
          ? ClashSyncSnapshot.fromJson(Map<String, dynamic>.from(snapshotRaw))
          : ClashSyncSnapshot(
              generatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            ),
    );
  }
}

/// Persiste el último backup local en SharedPreferences.
class ClashSyncLocalBackupStore {
  const ClashSyncLocalBackupStore({required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  static const storageKey = ClashSharedPreferencesKeys.lastLocalBackup;

  Future<bool> save(ClashSyncLocalBackup backup) async {
    try {
      return await sharedPreferences.setString(
        storageKey,
        jsonEncode(backup.toJson()),
      );
    } catch (_) {
      return false;
    }
  }

  ClashSyncLocalBackup? read() {
    final raw = sharedPreferences.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return ClashSyncLocalBackup.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

int? _readOptionalInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
