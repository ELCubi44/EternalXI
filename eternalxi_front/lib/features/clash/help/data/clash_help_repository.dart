import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';

/// Repositorio read-only de topics de ayuda Clash (Fase 51).
class ClashHelpRepository {
  ClashHelpRepository({required ClashHelpTopicsLocalDataSource dataSource})
    : _dataSource = dataSource;

  final ClashHelpTopicsLocalDataSource _dataSource;

  Future<List<ClashHelpTopic>> fetchTopics() => _dataSource.loadTopics();

  Future<ClashHelpTopic?> findById(String id) async {
    final topics = await fetchTopics();
    for (final topic in topics) {
      if (topic.id == id) {
        return topic;
      }
    }
    return null;
  }

  Future<List<ClashHelpTopic>> search({
    String query = '',
    ClashHelpCategory? category,
  }) async {
    final topics = await fetchTopics();
    return topics
        .where((topic) {
          if (category != null && topic.category != category) {
            return false;
          }
          return topic.matchesQuery(query);
        })
        .toList(growable: false);
  }
}
