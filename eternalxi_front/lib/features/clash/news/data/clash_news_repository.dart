import 'package:eternal_xi/features/clash/news/data/clash_news_local_datasource.dart';
import 'package:eternal_xi/features/clash/news/data/clash_news_read_storage.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_item.dart';
import 'package:eternal_xi/features/clash/news/domain/clash_news_type.dart';

/// Noticias locales Clash con lectura persistida (Fase 31).
class ClashNewsRepository {
  ClashNewsRepository({
    required ClashNewsLocalDataSource dataSource,
    required ClashNewsReadStorageBackend storage,
    DateTime Function()? now,
  }) : _dataSource = dataSource,
       _storage = storage,
       _now = now ?? DateTime.now;

  final ClashNewsLocalDataSource _dataSource;
  final ClashNewsReadStorageBackend _storage;
  final DateTime Function() _now;

  List<ClashNewsItem>? _newsCache;
  ClashNewsReadState? _stateCache;

  Future<List<ClashNewsItem>> _loadNewsCatalog() async {
    _newsCache ??= await _dataSource.loadNews();
    return _newsCache!;
  }

  Future<ClashNewsReadState> loadReadState() async {
    if (_stateCache != null) {
      return _stateCache!;
    }
    final stored = _storage.readState();
    _stateCache = stored ?? const ClashNewsReadState();
    if (stored == null) {
      await _storage.writeState(_stateCache!);
    }
    return _stateCache!;
  }

  static List<ClashNewsItem> sortNewsItems(List<ClashNewsItem> items) {
    final sorted = List<ClashNewsItem>.from(items);
    sorted.sort((a, b) {
      if (a.isPinned != b.isPinned) {
        return a.isPinned ? -1 : 1;
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return sorted;
  }

  Future<List<ClashNewsEntry>> fetchNewsEntries() async {
    final news = sortNewsItems(await _loadNewsCatalog());
    final state = await loadReadState();
    return news
        .map(
          (item) => ClashNewsEntry(
            item: item,
            isRead: state.readNewsIds.contains(item.id),
          ),
        )
        .toList(growable: false);
  }

  Future<ClashNewsSummary> fetchSummary() async {
    final entries = await fetchNewsEntries();
    final unread = entries.where((entry) => !entry.isRead).toList();
    return ClashNewsSummary(
      unreadCount: unread.length,
      latestUnreadTitle: unread.isEmpty ? null : unread.first.item.title,
    );
  }

  Future<void> markAsRead(String newsId) async {
    final state = await loadReadState();
    if (state.readNewsIds.contains(newsId)) {
      return;
    }
    final updated = state.copyWith(readNewsIds: {...state.readNewsIds, newsId});
    _stateCache = updated;
    await _storage.writeState(updated);
  }

  Future<void> markAllAsRead() async {
    final news = await _loadNewsCatalog();
    final updated = ClashNewsReadState(
      readNewsIds: news.map((item) => item.id).toSet(),
      lastOpenedAt: _now().toIso8601String(),
    );
    _stateCache = updated;
    await _storage.writeState(updated);
  }

  Future<void> recordOpened() async {
    final state = await loadReadState();
    final updated = state.copyWith(lastOpenedAt: _now().toIso8601String());
    _stateCache = updated;
    await _storage.writeState(updated);
  }

  static List<ClashNewsEntry> filterEntries(
    List<ClashNewsEntry> entries,
    ClashNewsFilter filter,
  ) {
    return entries
        .where((entry) {
          return switch (filter) {
            ClashNewsFilter.all => true,
            ClashNewsFilter.unread => !entry.isRead,
            ClashNewsFilter.updates => entry.item.type == ClashNewsType.update,
            ClashNewsFilter.events => entry.item.type == ClashNewsType.event,
            ClashNewsFilter.banners => entry.item.type == ClashNewsType.banner,
            ClashNewsFilter.notices => entry.item.type.isNotice,
          };
        })
        .toList(growable: false);
  }
}

enum ClashNewsFilter { all, unread, updates, events, banners, notices }
