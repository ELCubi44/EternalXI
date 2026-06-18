import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';

/// Ticket local de invocación (Fase 26).
class ClashGachaTicket {
  const ClashGachaTicket({
    required this.id,
    required this.name,
    required this.description,
    required this.compatibleBannerIds,
    required this.pullCount,
    this.rarityGuarantee,
    this.iconKey,
  });

  final String id;
  final String name;
  final String description;
  final List<String> compatibleBannerIds;
  final int pullCount;
  final ClashRarity? rarityGuarantee;
  final String? iconKey;

  bool isCompatibleWith(String bannerId) {
    return compatibleBannerIds.contains(bannerId);
  }

  factory ClashGachaTicket.fromJson(Map<String, dynamic> json) {
    final bannersRaw = json['compatibleBannerIds'] as List? ?? const [];
    final guaranteeRaw = json['rarityGuarantee'];
    return ClashGachaTicket(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      compatibleBannerIds: bannersRaw
          .map((id) => id.toString())
          .toList(growable: false),
      pullCount: clashAsInt(json['pullCount'], fallback: 1),
      rarityGuarantee: guaranteeRaw == null
          ? null
          : ClashRarity.fromJson(guaranteeRaw),
      iconKey: clashOptionalString(json['iconKey']),
    );
  }
}

/// Entrada de inventario de tickets.
class ClashGachaTicketInventoryEntry {
  const ClashGachaTicketInventoryEntry({
    required this.ticket,
    required this.quantity,
  });

  final ClashGachaTicket ticket;
  final int quantity;
}
