import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';
import 'package:eternal_xi/features/clash/story/presentation/controllers/clash_story_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concede roster Eternal XI N y desbloquea equipo/invocaciones al entrar en Clash.
class ClashStarterBootstrap {
  ClashStarterBootstrap({
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashStoryRepository storyRepository,
    ClashStoryController? storyController,
    SharedPreferences? sharedPreferences,
  })  : _collectionRepository = collectionRepository,
        _storyRepository = storyRepository,
        _storyController = storyController,
        _sharedPreferences = sharedPreferences;

  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashStoryRepository _storyRepository;
  final ClashStoryController? _storyController;
  final SharedPreferences? _sharedPreferences;

  static bool _ran = false;

  /// Pack one-shot: suficientes materiales/EXP/monedas para subir un personaje a SR.
  static const srProgressPackPrefsKey = 'clash_sr_progress_pack_v1';

  Future<void> runOnce() async {
    if (_ran) return;
    _ran = true;
    await _collectionRepository.grantEternalXiStarterNCards();
    await _storyRepository.ensureSummonUnlocked();
    await _grantSrProgressPackOnce();
    await _storyController?.load();
  }

  Future<void> _grantSrProgressPackOnce() async {
    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    if (prefs.getBool(srProgressPackPrefsKey) == true) {
      return;
    }

    await _collectionRepository.grantEvolutionMaterials({
      'insignia-r': 10,
      'insignia-sr': 5,
    });
    await _collectionRepository.grantExpMaterials({
      'basic-training-manual': 40,
      'advanced-training-manual': 30,
      'master-training-manual': 40,
    });
    await _storyRepository.addCoins(10000);
    await prefs.setBool(srProgressPackPrefsKey, true);
  }
}
