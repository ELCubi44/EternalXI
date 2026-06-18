import 'dart:convert';

import 'package:eternal_xi/features/clash/events/domain/clash_character_event.dart';
import 'package:flutter/services.dart';

class ClashCharacterEventsLocalDataSource {
  ClashCharacterEventsLocalDataSource({
    this.assetPath = 'assets/data/clash/character_events.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  List<ClashCharacterEvent>? _cache;

  Future<List<ClashCharacterEvent>> loadEvents() async {
    _cache ??= await _loadFromAsset();
    return _cache!;
  }

  Future<List<ClashCharacterEvent>> _loadFromAsset() async {
    final raw = await _bundle.loadString(assetPath);
    return parseEventsJson(raw);
  }

  List<ClashCharacterEvent> parseEventsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de eventos Clash debe ser un objeto');
    }
    final eventsRaw = decoded['events'];
    if (eventsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: events');
    }
    return eventsRaw
        .map(
          (item) => ClashCharacterEvent.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  }

  void clearCacheForTests() {
    _cache = null;
  }
}
