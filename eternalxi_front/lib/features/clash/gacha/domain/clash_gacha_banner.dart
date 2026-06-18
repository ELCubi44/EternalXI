import 'package:eternal_xi/features/clash/cards/domain/clash_json_helpers.dart';

class ClashGachaBanner {
  const ClashGachaBanner({
    required this.id,
    required this.name,
    required this.description,
    required this.singleCost,
    required this.multiCost,
    required this.multiCount,
    required this.dailyDiscountCost,
    required this.dailyDiscountAvailable,
    this.poolCardIds = const [],
  });

  final String id;
  final String name;
  final String description;
  final int singleCost;
  final int multiCost;
  final int multiCount;
  final int dailyDiscountCost;
  final bool dailyDiscountAvailable;
  final List<String> poolCardIds;

  factory ClashGachaBanner.fromJson(Map<String, dynamic> json) {
    final poolRaw = json['poolCardIds'] as List? ?? const [];
    return ClashGachaBanner(
      id: clashRequireString(json['id'], 'id'),
      name: clashRequireString(json['name'], 'name'),
      description: clashRequireString(json['description'], 'description'),
      singleCost: clashRequireInt(json['singleCost'], 'singleCost'),
      multiCost: clashRequireInt(json['multiCost'], 'multiCost'),
      multiCount: clashRequireInt(json['multiCount'], 'multiCount'),
      dailyDiscountCost: clashRequireInt(
        json['dailyDiscountCost'],
        'dailyDiscountCost',
      ),
      dailyDiscountAvailable: json['dailyDiscountAvailable'] == true,
      poolCardIds: poolRaw.map((id) => id.toString()).toList(growable: false),
    );
  }
}
