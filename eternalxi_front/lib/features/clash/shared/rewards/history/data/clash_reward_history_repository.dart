import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/data/clash_reward_history_storage.dart';
import 'package:eternal_xi/features/clash/shared/rewards/history/domain/clash_reward_history_entry.dart';

/// Repositorio del historial local de recompensas Clash (Fase 60).
class ClashRewardHistoryRepository {
  ClashRewardHistoryRepository({
    required ClashRewardHistoryStorageBackend storage,
  }) : _storage = storage;

  final ClashRewardHistoryStorageBackend _storage;
  var _nextId = 0;

  List<ClashRewardHistoryEntry> loadEntries() => _storage.readEntries();

  Future<void> appendEntry(ClashRewardHistoryEntry entry) =>
      _storage.appendEntry(entry);

  Future<void> recordGrant({
    required ClashRewardHistorySourceType sourceType,
    required String title,
    required ClashRewardGrantResult result,
    String? sourceId,
  }) {
    return appendEntry(
      ClashRewardHistoryEntry.fromGrant(
        id: _newId(),
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
        result: result,
      ),
    );
  }

  Future<void> recordFailure({
    required ClashRewardHistorySourceType sourceType,
    required String title,
    String? sourceId,
  }) {
    return appendEntry(
      ClashRewardHistoryEntry.failure(
        id: _newId(),
        sourceType: sourceType,
        sourceId: sourceId,
        title: title,
      ),
    );
  }

  String _newId() {
    _nextId += 1;
    final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
    return 'crh_${stamp}_$_nextId';
  }
}
