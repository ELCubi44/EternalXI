import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_grant_result.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_ids.dart';
import 'package:eternal_xi/features/clash/story/data/repositories/clash_story_repository.dart';

/// Concede recompensas locales unificadas de Clash (Fase 53).
class ClashLocalRewardGranter {
  ClashLocalRewardGranter({
    required ClashPlayerCollectionRepository collectionRepository,
    ClashGachaTicketRepository? ticketRepository,
    ClashStoryRepository? storyRepository,
  }) : _collectionRepository = collectionRepository,
       _ticketRepository = ticketRepository,
       _storyRepository = storyRepository;

  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashGachaTicketRepository? _ticketRepository;
  final ClashStoryRepository? _storyRepository;

  static const knownExpMaterialIds = ClashRewardIds.expMaterials;

  static const knownTechniqueBookIds = ClashRewardIds.techniqueBooks;

  static const knownEvolutionMaterialIds = ClashRewardIds.evolutionMaterials;

  static const knownTicketIds = ClashRewardIds.tickets;

  Future<ClashRewardGrantResult> grantAll(
    List<ClashReward> rewards, {
    bool grantWallet = true,
  }) async {
    if (rewards.isEmpty) {
      return const ClashRewardGrantResult();
    }

    final granted = <ClashReward>[];
    final failed = <ClashFailedReward>[];
    var coinsAdded = 0;
    var gemsAdded = 0;
    final itemCounts = <String, int>{};
    final newlyGrantedCardIds = <String>[];
    final duplicateCardIds = <String>[];

    final expGrants = <String, int>{};
    final bookGrants = <String, int>{};
    final evolutionGrants = <String, int>{};
    final ticketGrants = <String, int>{};
    final pendingItemRewards = <ClashReward>[];
    final deferredCards = <ClashReward>[];

    void addItemCount(String key, int quantity) {
      if (quantity <= 0) {
        return;
      }
      itemCounts[key] = (itemCounts[key] ?? 0) + quantity;
    }

    for (final reward in rewards) {
      switch (reward.kind) {
        case ClashRewardKind.coins:
          if (!grantWallet || reward.amount <= 0) {
            continue;
          }
          final story = _storyRepository;
          if (story == null) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'wallet_unavailable'),
            );
            continue;
          }
          try {
            await story.addCoins(reward.amount);
            coinsAdded += reward.amount;
            granted.add(reward);
          } catch (_) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'coins_grant_failed'),
            );
          }
        case ClashRewardKind.gems:
          if (!grantWallet || reward.amount <= 0) {
            continue;
          }
          final story = _storyRepository;
          if (story == null) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'wallet_unavailable'),
            );
            continue;
          }
          try {
            await story.addGems(reward.amount);
            gemsAdded += reward.amount;
            granted.add(reward);
          } catch (_) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'gems_grant_failed'),
            );
          }
        case ClashRewardKind.expMaterial:
          final id = reward.itemId;
          if (id == null || reward.amount <= 0) {
            continue;
          }
          if (!knownExpMaterialIds.contains(id)) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'unknown_exp_material'),
            );
            continue;
          }
          expGrants[id] = (expGrants[id] ?? 0) + reward.amount;
          pendingItemRewards.add(reward);
        case ClashRewardKind.techniqueBook:
          final id = reward.itemId;
          if (id == null || reward.amount <= 0) {
            continue;
          }
          if (!knownTechniqueBookIds.contains(id)) {
            failed.add(
              ClashFailedReward(
                reward: reward,
                error: 'unknown_technique_book',
              ),
            );
            continue;
          }
          bookGrants[id] = (bookGrants[id] ?? 0) + reward.amount;
          pendingItemRewards.add(reward);
        case ClashRewardKind.evolutionMaterial:
          final id = reward.itemId;
          if (id == null || reward.amount <= 0) {
            continue;
          }
          if (!knownEvolutionMaterialIds.contains(id)) {
            failed.add(
              ClashFailedReward(
                reward: reward,
                error: 'unknown_evolution_material',
              ),
            );
            continue;
          }
          evolutionGrants[id] = (evolutionGrants[id] ?? 0) + reward.amount;
          pendingItemRewards.add(reward);
        case ClashRewardKind.ticket:
          final id = reward.itemId;
          if (id == null || reward.amount <= 0) {
            continue;
          }
          if (_ticketRepository == null) {
            failed.add(
              ClashFailedReward(
                reward: reward,
                error: 'ticket_repository_unavailable',
              ),
            );
            continue;
          }
          if (!knownTicketIds.contains(id)) {
            failed.add(
              ClashFailedReward(reward: reward, error: 'unknown_ticket'),
            );
            continue;
          }
          ticketGrants[id] = (ticketGrants[id] ?? 0) + reward.amount;
          pendingItemRewards.add(reward);
        case ClashRewardKind.cardMissing:
        case ClashRewardKind.cardDuplicate:
        case ClashRewardKind.featuredCard:
        case ClashRewardKind.starterRoster:
          deferredCards.add(reward);
      }
    }

    if (pendingItemRewards.isNotEmpty) {
      try {
        if (expGrants.isNotEmpty) {
          await _collectionRepository.grantExpMaterials(expGrants);
        }
        if (bookGrants.isNotEmpty) {
          await _collectionRepository.grantTechniqueBooks(bookGrants);
        }
        if (evolutionGrants.isNotEmpty) {
          await _collectionRepository.grantEvolutionMaterials(evolutionGrants);
        }
        if (ticketGrants.isNotEmpty) {
          await _ticketRepository!.grantTickets(ticketGrants);
        }
        granted.addAll(pendingItemRewards);
        for (final reward in pendingItemRewards) {
          final id = reward.itemId;
          if (id == null) {
            continue;
          }
          final prefix = switch (reward.kind) {
            ClashRewardKind.expMaterial => 'exp',
            ClashRewardKind.techniqueBook => 'book',
            ClashRewardKind.evolutionMaterial => 'evo',
            ClashRewardKind.ticket => 'ticket',
            _ => 'item',
          };
          addItemCount('$prefix:$id', reward.amount);
        }
      } catch (_) {
        failed.addAll(
          pendingItemRewards.map(
            (reward) => ClashFailedReward(
              reward: reward,
              error: 'inventory_grant_failed',
            ),
          ),
        );
      }
    }

    for (final reward in deferredCards) {
      try {
        switch (reward.kind) {
          case ClashRewardKind.starterRoster:
            if (reward.starterRosterKey ==
                ClashRewardIds.eternalXiStarterRosterKey) {
              newlyGrantedCardIds.addAll(
                await _collectionRepository.grantEternalXiStarterNCards(),
              );
              granted.add(reward);
            } else {
              failed.add(
                ClashFailedReward(
                  reward: reward,
                  error: 'unknown_starter_roster',
                ),
              );
            }
          case ClashRewardKind.cardMissing:
            final cardId = reward.itemId;
            if (cardId == null) {
              continue;
            }
            newlyGrantedCardIds.addAll(
              await _collectionRepository.grantMissingCardIds([cardId]),
            );
            granted.add(reward);
          case ClashRewardKind.cardDuplicate:
            final cardId = reward.itemId;
            if (cardId == null) {
              continue;
            }
            await _collectionRepository.grantCardCopy(cardId);
            duplicateCardIds.add(cardId);
            granted.add(reward);
          case ClashRewardKind.featuredCard:
            final cardId = reward.itemId;
            if (cardId == null) {
              continue;
            }
            final owned = _collectionRepository.loadOwnedCardIds();
            if (!owned.contains(cardId)) {
              newlyGrantedCardIds.addAll(
                await _collectionRepository.grantMissingCardIds([cardId]),
              );
            } else if (reward.featuredCardAsDuplicate ||
                owned.contains(cardId)) {
              await _collectionRepository.grantCardCopy(cardId);
              duplicateCardIds.add(cardId);
            }
            granted.add(reward);
          default:
            break;
        }
      } catch (_) {
        failed.add(
          ClashFailedReward(reward: reward, error: 'card_grant_failed'),
        );
      }
    }

    return ClashRewardGrantResult(
      grantedRewards: granted,
      failedRewards: failed,
      coinsAdded: coinsAdded,
      gemsAdded: gemsAdded,
      itemCounts: itemCounts,
      newlyGrantedCardIds: newlyGrantedCardIds,
      duplicateCardIds: duplicateCardIds,
    );
  }
}
