import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_local_reward_granter.dart';
import 'package:eternal_xi/features/clash/shared/rewards/data/clash_reward_converters.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';

/// Puente legacy hacia [ClashLocalRewardGranter] (Fase 27 + 53).
class ClashShopGrantService {
  ClashShopGrantService({
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashGachaTicketRepository ticketRepository,
    ClashLocalRewardGranter? rewardGranter,
  }) : _rewardGranter =
           rewardGranter ??
           ClashLocalRewardGranter(
             collectionRepository: collectionRepository,
             ticketRepository: ticketRepository,
           );

  final ClashLocalRewardGranter _rewardGranter;

  ClashLocalRewardGranter get rewardGranter => _rewardGranter;

  Future<bool> grantProductGrants(List<ClashShopProductGrant> grants) async {
    final result = await _rewardGranter.grantAll(
      ClashRewardConverters.fromProductGrants(grants),
      grantWallet: false,
    );
    return result.isFullyGranted;
  }
}
