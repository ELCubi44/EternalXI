import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';

/// Concede roster Eternal XI N y desbloquea equipo/invocaciones al entrar en Clash.
class ClashStarterBootstrap {
  ClashStarterBootstrap({
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashStoryRepository storyRepository,
    ClashStoryController? storyController,
  })  : _collectionRepository = collectionRepository,
        _storyRepository = storyRepository,
        _storyController = storyController;

  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashStoryRepository _storyRepository;
  final ClashStoryController? _storyController;

  static bool _ran = false;

  Future<void> runOnce() async {
    if (_ran) return;
    _ran = true;
    await _collectionRepository.grantEternalXiStarterNCards();
    await _storyRepository.ensureSummonUnlocked();
    await _storyController?.load();
  }
}
