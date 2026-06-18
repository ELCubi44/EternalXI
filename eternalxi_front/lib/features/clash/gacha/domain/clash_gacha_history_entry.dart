import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_result.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pull_type.dart';

/// Resultado de una carta guardado en el historial (Fase 24).
class ClashGachaHistoryResultItem {
  const ClashGachaHistoryResultItem({
    required this.cardId,
    required this.cardName,
    required this.rarity,
    required this.isNew,
    required this.isDuplicate,
    required this.upgradedRarity,
    required this.duplicateCopiesAfter,
  });

  final String cardId;
  final String cardName;
  final ClashRarity rarity;
  final bool isNew;
  final bool isDuplicate;
  final bool upgradedRarity;
  final int duplicateCopiesAfter;

  factory ClashGachaHistoryResultItem.fromPullItem(
    ClashGachaPullResultItem item,
  ) {
    return ClashGachaHistoryResultItem(
      cardId: item.cardId,
      cardName: item.cardName,
      rarity: item.rarity,
      isNew: item.isNew,
      isDuplicate: item.isDuplicate,
      upgradedRarity: item.upgradedRarity,
      duplicateCopiesAfter: item.duplicateCopiesAfter,
    );
  }

  factory ClashGachaHistoryResultItem.fromJson(Map<String, dynamic> json) {
    return ClashGachaHistoryResultItem(
      cardId: json['cardId'] as String? ?? '',
      cardName: json['cardName'] as String? ?? '',
      rarity: ClashRarity.fromJson(json['rarity']),
      isNew: json['isNew'] as bool? ?? false,
      isDuplicate: json['isDuplicate'] as bool? ?? false,
      upgradedRarity: json['upgradedRarity'] as bool? ?? false,
      duplicateCopiesAfter: json['duplicateCopiesAfter'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'cardId': cardId,
    'cardName': cardName,
    'rarity': rarity.toJson(),
    'isNew': isNew,
    'isDuplicate': isDuplicate,
    'upgradedRarity': upgradedRarity,
    'duplicateCopiesAfter': duplicateCopiesAfter,
  };
}

/// Tirada guardada en historial local (Fase 24).
class ClashGachaHistoryEntry {
  const ClashGachaHistoryEntry({
    required this.id,
    required this.bannerId,
    required this.bannerName,
    required this.pullType,
    required this.spentGems,
    required this.createdAt,
    required this.results,
  });

  final String id;
  final String bannerId;
  final String bannerName;
  final ClashGachaPullType pullType;
  final int spentGems;
  final DateTime createdAt;
  final List<ClashGachaHistoryResultItem> results;

  static const maxStoredEntries = 50;

  ClashRarity get bestRarity {
    if (results.isEmpty) {
      return ClashRarity.n;
    }
    return results
        .map((item) => item.rarity)
        .reduce(
          (best, current) =>
              ClashRarity.values.indexOf(current) >
                  ClashRarity.values.indexOf(best)
              ? current
              : best,
        );
  }

  factory ClashGachaHistoryEntry.fromPullResult({
    required String id,
    required ClashGachaPullResult result,
    required String bannerName,
  }) {
    return ClashGachaHistoryEntry(
      id: id,
      bannerId: result.bannerId,
      bannerName: bannerName,
      pullType: result.pullType,
      spentGems: result.spentGems,
      createdAt: result.createdAt,
      results: result.results
          .map(ClashGachaHistoryResultItem.fromPullItem)
          .toList(growable: false),
    );
  }

  factory ClashGachaHistoryEntry.fromJson(Map<String, dynamic> json) {
    final resultsRaw = json['results'] as List? ?? const [];
    return ClashGachaHistoryEntry(
      id: json['id'] as String? ?? '',
      bannerId: json['bannerId'] as String? ?? '',
      bannerName: json['bannerName'] as String? ?? '',
      pullType: _pullTypeFromJson(json['pullType']),
      spentGems: json['spentGems'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      results: resultsRaw
          .map(
            (item) => ClashGachaHistoryResultItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bannerId': bannerId,
    'bannerName': bannerName,
    'pullType': pullType.name,
    'spentGems': spentGems,
    'createdAt': createdAt.toIso8601String(),
    'results': results.map((item) => item.toJson()).toList(growable: false),
  };

  static ClashGachaPullType _pullTypeFromJson(Object? value) {
    final raw = value?.toString().trim();
    return ClashGachaPullType.values.firstWhere(
      (type) => type.name == raw,
      orElse: () => ClashGachaPullType.single,
    );
  }
}
