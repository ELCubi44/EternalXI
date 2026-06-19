import 'dart:convert';

import 'package:eternal_xi/features/clash/cards/domain/clash_player_style.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_position.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_rarity.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_level.dart';
import 'package:eternal_xi/features/clash/cards/domain/clash_technique_type.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_pity_state.dart';
import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_rarity_rates.dart';
import 'package:eternal_xi/features/clash/shared/rewards/domain/clash_reward_ids.dart';
import 'package:eternal_xi/features/clash/shop/domain/clash_shop_product_type.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const clashAssetStatKeys = <String>[
  'save',
  'defense',
  'pass',
  'dribble',
  'shot',
  'techniquePoints',
  'stamina',
];

const clashCanonicalPositions = <String>{
  'goalkeeper',
  'centreBack',
  'fullBack',
  'defensiveMidfielder',
  'attackingMidfielder',
  'winger',
  'striker',
};

Future<Map<String, dynamic>> loadClashAssetJson(String assetPath) async {
  final raw = await rootBundle.loadString(assetPath);
  final decoded = jsonDecode(raw);
  if (decoded is! Map<String, dynamic>) {
    throw FormatException('$assetPath debe ser un objeto JSON');
  }
  return decoded;
}

void assertUniqueIds(Iterable<String> ids, String collectionName) {
  final seen = <String>{};
  for (final id in ids) {
    expect(
      id.trim().isNotEmpty,
      isTrue,
      reason: '$collectionName contiene un id vacío',
    );
    expect(
      seen.add(id),
      isTrue,
      reason: '$collectionName contiene id duplicado: $id',
    );
  }
}

void assertRequiredString(
  Map<String, dynamic> json,
  String field,
  String context,
) {
  final value = json[field];
  expect(value, isA<String>(), reason: '$context.$field debe ser string');
  expect(
    (value as String).trim().isNotEmpty,
    isTrue,
    reason: '$context.$field no puede estar vacío',
  );
}

void assertNonNegativeNumber(
  Object? value,
  String field,
  String context, {
  bool positive = false,
}) {
  expect(value, isA<num>(), reason: '$context.$field debe ser numérico');
  final number = (value as num).toInt();
  if (positive) {
    expect(number, greaterThan(0), reason: '$context.$field debe ser > 0');
  } else {
    expect(number, greaterThanOrEqualTo(0), reason: '$context.$field >= 0');
  }
}

void assertPositiveQuantity(Object? value, String context) {
  assertNonNegativeNumber(value, 'quantity', context, positive: true);
}

void validateStats(Map<String, dynamic> stats, String context) {
  for (final key in clashAssetStatKeys) {
    expect(stats.containsKey(key), isTrue, reason: '$context.stats falta $key');
    assertNonNegativeNumber(stats[key], key, '$context.stats');
  }
}

void validateSuperTechnique(Map<String, dynamic> json, String context) {
  assertRequiredString(json, 'id', context);
  assertRequiredString(json, 'name', context);
  assertRequiredString(json, 'description', context);
  ClashTechniqueType.fromJson(json['type']);
  ClashPlayerStyle.fromJson(json['style']);
  assertNonNegativeNumber(
    json['basePower'],
    'basePower',
    context,
    positive: true,
  );
  assertNonNegativeNumber(json['ptCost'], 'ptCost', context, positive: true);
  ClashTechniqueLevel.fromJson(json['level']);
}

void validateTypedItemReward(
  Map<String, dynamic>? item,
  String context, {
  required bool Function(String id) isKnownId,
  required String kind,
}) {
  expect(item, isA<Map>(), reason: '$context debe ser objeto');
  final map = Map<String, dynamic>.from(item!);
  assertRequiredString(map, 'id', context);
  final id = map['id'] as String;
  expect(isKnownId(id), isTrue, reason: '$context.$kind id desconocido: $id');
  assertPositiveQuantity(map['quantity'], context);
}

void validateGrantReward(
  Map<String, dynamic> reward,
  String context, {
  required Set<String> cardIds,
}) {
  if (reward.isEmpty) {
    return;
  }

  if (reward.containsKey('coins')) {
    assertNonNegativeNumber(reward['coins'], 'coins', context, positive: true);
  }
  if (reward.containsKey('gems')) {
    assertNonNegativeNumber(reward['gems'], 'gems', context, positive: true);
  }
  if (reward.containsKey('expMaterial')) {
    validateTypedItemReward(
      Map<String, dynamic>.from(reward['expMaterial'] as Map),
      '$context.expMaterial',
      isKnownId: ClashRewardIds.isKnownExpMaterial,
      kind: 'expMaterial',
    );
  }
  if (reward.containsKey('techniqueBook')) {
    validateTypedItemReward(
      Map<String, dynamic>.from(reward['techniqueBook'] as Map),
      '$context.techniqueBook',
      isKnownId: ClashRewardIds.isKnownTechniqueBook,
      kind: 'techniqueBook',
    );
  }
  if (reward.containsKey('evolutionMaterial')) {
    validateTypedItemReward(
      Map<String, dynamic>.from(reward['evolutionMaterial'] as Map),
      '$context.evolutionMaterial',
      isKnownId: ClashRewardIds.isKnownEvolutionMaterial,
      kind: 'evolutionMaterial',
    );
  }
  if (reward.containsKey('ticket')) {
    validateTypedItemReward(
      Map<String, dynamic>.from(reward['ticket'] as Map),
      '$context.ticket',
      isKnownId: ClashRewardIds.isKnownTicket,
      kind: 'ticket',
    );
  }
  if (reward.containsKey('featuredCardId')) {
    final cardId = reward['featuredCardId']?.toString() ?? '';
    expect(
      cardIds.contains(cardId),
      isTrue,
      reason: '$context.featuredCardId no existe en cards.json: $cardId',
    );
  }
  if (reward.containsKey('cardIds')) {
    final ids = (reward['cardIds'] as List? ?? const [])
        .map((id) => id.toString())
        .toList();
    for (final cardId in ids) {
      expect(
        cardIds.contains(cardId),
        isTrue,
        reason: '$context.cardIds referencia carta inexistente: $cardId',
      );
    }
  }
  if (reward.containsKey('starterRosterKey')) {
    expect(
      reward['starterRosterKey'],
      ClashRewardIds.eternalXiStarterRosterKey,
      reason: '$context.starterRosterKey desconocido',
    );
  }
}

void validateStoryFlavorItems(List<dynamic> items, String context) {
  for (final raw in items) {
    final item = Map<String, dynamic>.from(raw as Map);
    assertRequiredString(item, 'id', context);
    assertRequiredString(item, 'name', context);
    assertPositiveQuantity(item['quantity'], context);
    final mapped = ClashRewardIds.storyItemToExpMaterial[item['id'] as String];
    if (mapped != null) {
      expect(
        ClashRewardIds.isKnownExpMaterial(mapped),
        isTrue,
        reason: '$context item ${item['id']} mapea a material desconocido',
      );
    }
  }
}

void validateStoryMaterials(List<dynamic> materials, String context) {
  for (final raw in materials) {
    final material = Map<String, dynamic>.from(raw as Map);
    assertRequiredString(material, 'id', context);
    assertPositiveQuantity(material['quantity'], context);
    expect(
      ClashRewardIds.isKnownGrantableItemId(material['id'] as String),
      isTrue,
      reason: '$context.materials id desconocido: ${material['id']}',
    );
  }
}

void validateStoryReward(
  Map<String, dynamic> reward,
  String context, {
  required Set<String> cardIds,
}) {
  if (reward.containsKey('coins')) {
    assertNonNegativeNumber(reward['coins'], 'coins', context);
  }
  if (reward.containsKey('gems')) {
    assertNonNegativeNumber(reward['gems'], 'gems', context);
  }
  validateGrantReward(reward, context, cardIds: cardIds);
  validateStoryFlavorItems(reward['items'] as List? ?? const [], context);
  validateStoryMaterials(reward['materials'] as List? ?? const [], context);
}

void validateRivalLineup(List<dynamic> lineup, String teamId) {
  expect(lineup.length, 7, reason: '$teamId.lineup7v7 debe tener 7 jugadores');
  final positions = <String>{};
  for (final raw in lineup) {
    final player = Map<String, dynamic>.from(raw as Map);
    final context = '$teamId.${player['id']}';
    assertRequiredString(player, 'id', context);
    assertNonNegativeNumber(
      player['playerId'],
      'playerId',
      context,
      positive: true,
    );
    assertRequiredString(player, 'name', context);
    final position = ClashPosition.fromJson(player['position']).toJson();
    expect(
      clashCanonicalPositions.contains(position),
      isTrue,
      reason: '$context.position inválida: $position',
    );
    expect(
      positions.add(position),
      isTrue,
      reason: '$teamId repite posición $position',
    );
    ClashPlayerStyle.fromJson(player['style']);
    ClashRarity.fromJson(player['rarity']);
    assertNonNegativeNumber(player['level'], 'level', context, positive: true);
    validateStats(Map<String, dynamic>.from(player['stats'] as Map), context);
    final techniques = player['superTechniques'] as List? ?? const [];
    for (final techniqueRaw in techniques) {
      validateSuperTechnique(
        Map<String, dynamic>.from(techniqueRaw as Map),
        '$context.superTechnique',
      );
    }
  }
  expect(
    positions,
    clashCanonicalPositions,
    reason: '$teamId.lineup7v7 debe cubrir las 7 posiciones oficiales',
  );
}

void validateShopGrant(Map<String, dynamic> grant, String context) {
  final type = ClashShopProductType.fromJson(grant['type']);
  expect(type, isNotNull, reason: '$context.type desconocido');
  assertRequiredString(grant, 'id', context);
  assertPositiveQuantity(grant['quantity'], context);
  switch (type!) {
    case ClashShopProductType.expMaterial:
      expect(
        ClashRewardIds.isKnownExpMaterial(grant['id'] as String),
        isTrue,
        reason: '$context id exp desconocido',
      );
    case ClashShopProductType.techniqueBook:
      expect(
        ClashRewardIds.isKnownTechniqueBook(grant['id'] as String),
        isTrue,
        reason: '$context id libro desconocido',
      );
    case ClashShopProductType.evolutionMaterial:
      expect(
        ClashRewardIds.isKnownEvolutionMaterial(grant['id'] as String),
        isTrue,
        reason: '$context id evolución desconocido',
      );
    case ClashShopProductType.ticket:
      expect(
        ClashRewardIds.isKnownTicket(grant['id'] as String),
        isTrue,
        reason: '$context id ticket desconocido',
      );
  }
}

void validateGachaRates(Map<String, dynamic> ratesJson) {
  final rates = ClashGachaRarityRates.fromJson(ratesJson);
  expect(
    rates.totalPercent,
    100,
    reason: 'gacha rates deben sumar 100 (actual: ${rates.totalPercent})',
  );
  for (final entry in rates.weightedEntries) {
    expect(
      entry.$2,
      greaterThanOrEqualTo(0),
      reason: 'rate ${entry.$1} negativa',
    );
  }
}

void validateGachaBanner(
  Map<String, dynamic> banner,
  String context, {
  required Set<String> cardIds,
}) {
  assertRequiredString(banner, 'id', context);
  assertRequiredString(banner, 'name', context);
  assertRequiredString(banner, 'description', context);
  assertNonNegativeNumber(
    banner['singleCost'],
    'singleCost',
    context,
    positive: true,
  );
  assertNonNegativeNumber(
    banner['multiCost'],
    'multiCost',
    context,
    positive: true,
  );
  assertNonNegativeNumber(
    banner['multiCount'],
    'multiCount',
    context,
    positive: true,
  );
  assertNonNegativeNumber(
    banner['dailyDiscountCost'],
    'dailyDiscountCost',
    context,
    positive: true,
  );
  final pool = (banner['poolCardIds'] as List? ?? const [])
      .map((id) => id.toString())
      .toList();
  for (final cardId in pool) {
    expect(
      cardIds.contains(cardId),
      isTrue,
      reason: '$context.poolCardIds referencia carta inexistente: $cardId',
    );
  }
  expect(
    ClashGachaPityState.defaultThreshold,
    greaterThan(0),
    reason: 'pity threshold por defecto debe ser > 0',
  );
}

void validateGachaTicket(
  Map<String, dynamic> ticket,
  String context, {
  required Set<String> bannerIds,
}) {
  assertRequiredString(ticket, 'id', context);
  assertRequiredString(ticket, 'name', context);
  assertRequiredString(ticket, 'description', context);
  assertNonNegativeNumber(
    ticket['pullCount'],
    'pullCount',
    context,
    positive: true,
  );
  expect(
    ClashRewardIds.isKnownTicket(ticket['id'] as String),
    isTrue,
    reason: '$context id ticket desconocido',
  );
  final banners = (ticket['compatibleBannerIds'] as List? ?? const [])
      .map((id) => id.toString())
      .toList();
  expect(banners, isNotEmpty, reason: '$context.compatibleBannerIds vacío');
  for (final bannerId in banners) {
    expect(
      bannerIds.contains(bannerId),
      isTrue,
      reason: '$context referencia banner inexistente: $bannerId',
    );
  }
  final guarantee = ticket['rarityGuarantee'];
  if (guarantee != null) {
    ClashRarity.fromJson(guarantee);
  }
}
