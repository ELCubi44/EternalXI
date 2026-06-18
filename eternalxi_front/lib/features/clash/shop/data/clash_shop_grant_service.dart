import 'package:eternal_xi/features/clash/cards/data/repositories/clash_player_collection_repository.dart';
import 'package:eternal_xi/features/clash/gacha/data/clash_gacha_ticket_repository.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';

/// Concede recompensas locales de tienda/historia a inventarios Clash (Fase 27).
class ClashShopGrantService {
  ClashShopGrantService({
    required ClashPlayerCollectionRepository collectionRepository,
    required ClashGachaTicketRepository ticketRepository,
  }) : _collectionRepository = collectionRepository,
       _ticketRepository = ticketRepository;

  final ClashPlayerCollectionRepository _collectionRepository;
  final ClashGachaTicketRepository _ticketRepository;

  Future<bool> grantProductGrants(List<ClashShopProductGrant> grants) async {
    if (grants.isEmpty) {
      return true;
    }

    final expGrants = <String, int>{};
    final bookGrants = <String, int>{};
    final evolutionGrants = <String, int>{};
    final ticketGrants = <String, int>{};

    for (final grant in grants) {
      if (grant.quantity <= 0) {
        continue;
      }
      switch (grant.type) {
        case ClashShopProductType.expMaterial:
          expGrants[grant.id] = (expGrants[grant.id] ?? 0) + grant.quantity;
        case ClashShopProductType.techniqueBook:
          bookGrants[grant.id] = (bookGrants[grant.id] ?? 0) + grant.quantity;
        case ClashShopProductType.evolutionMaterial:
          evolutionGrants[grant.id] =
              (evolutionGrants[grant.id] ?? 0) + grant.quantity;
        case ClashShopProductType.ticket:
          ticketGrants[grant.id] =
              (ticketGrants[grant.id] ?? 0) + grant.quantity;
      }
    }

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
        await _ticketRepository.grantTickets(ticketGrants);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
