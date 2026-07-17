import 'package:eternal_xi/data/services/user_api_service.dart';
import 'package:eternal_xi/features/clash/cards/data/repositories/clash_cards_repository.dart';
import 'package:flutter/foundation.dart';

/// Sincroniza desbloqueos de avatar en backend al obtener cartas Clash.
class ClashAvatarUnlockSync {
  ClashAvatarUnlockSync({
    required UserApiService userApi,
    required ClashCardsRepository cardsRepository,
    required int Function() currentUserId,
  }) : _userApi = userApi,
       _cardsRepository = cardsRepository,
       _currentUserId = currentUserId;

  final UserApiService _userApi;
  final ClashCardsRepository _cardsRepository;
  final int Function() _currentUserId;

  Future<void> syncOwnedCardIds(Iterable<String> cardIds) async {
    final userId = _currentUserId();
    if (userId <= 0 || cardIds.isEmpty) {
      return;
    }
    final playerIds = <int>{};
    for (final cardId in cardIds) {
      final entry = await _cardsRepository.findById(cardId);
      final pid = entry?.card.playerId;
      if (pid != null && pid > 0) {
        playerIds.add(pid);
      }
    }
    if (playerIds.isEmpty) {
      return;
    }
    try {
      await _userApi.registerAvatarUnlocks(
        userId: userId,
        playerIds: playerIds.toList(growable: false),
        origen: 'clash',
      );
    } catch (e, st) {
      debugPrint('[ClashAvatarUnlockSync] $e\n$st');
    }
  }
}
