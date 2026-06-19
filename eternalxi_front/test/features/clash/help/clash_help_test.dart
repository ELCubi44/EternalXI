import 'package:eternal_xi/features/clash/help/data/clash_help_repository.dart';
import 'package:eternal_xi/features/clash/help/data/clash_help_topics_local_datasource.dart';
import 'package:eternal_xi/features/clash/help/domain/clash_help_topic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ClashHelpRepository repository;

  setUp(() {
    final dataSource = ClashHelpTopicsLocalDataSource();
    dataSource.clearCacheForTests();
    repository = ClashHelpRepository(dataSource: dataSource);
  });

  group('ClashHelpRepository Fase 51', () {
    test('carga help_topics.json', () async {
      final topics = await repository.fetchTopics();
      expect(topics, isNotEmpty);
      expect(topics.first.id, 'clash_intro');
    });

    test('hay al menos 10 topics', () async {
      final topics = await repository.fetchTopics();
      expect(topics.length, greaterThanOrEqualTo(10));
    });

    test('búsqueda por pity encuentra Invocar', () async {
      final results = await repository.search(query: 'pity');
      expect(results.any((topic) => topic.id == 'summon'), isTrue);
    });

    test('filtro categoría Partido devuelve match PT techniques', () async {
      final results = await repository.search(
        category: ClashHelpCategory.match,
      );
      final ids = results.map((topic) => topic.id).toSet();
      expect(ids, containsAll(['match_basics', 'pt_stamina', 'techniques']));
    });

    test('topic con relatedRoutes parsea', () async {
      final topic = await repository.findById('clash_intro');
      expect(topic, isNotNull);
      expect(topic!.relatedRoutes, isNotEmpty);
      expect(topic.relatedRoutes.first.path, '/clash/story');
    });
  });
}
