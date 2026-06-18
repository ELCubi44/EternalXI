import 'dart:convert';

import 'package:eternal_xi/features/clash/gacha/domain/clash_gacha_ticket.dart';
import 'package:flutter/services.dart';

class ClashGachaTicketsLocalDataSource {
  ClashGachaTicketsLocalDataSource({
    this.assetPath = 'assets/data/clash/gacha_tickets.json',
    AssetBundle? bundle,
  }) : _bundle = bundle ?? rootBundle;

  final String assetPath;
  final AssetBundle _bundle;

  Future<List<ClashGachaTicket>> loadTickets() async {
    final raw = await _bundle.loadString(assetPath);
    return parseTicketsJson(raw);
  }

  List<ClashGachaTicket> parseTicketsJson(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('JSON de tickets Clash debe ser un objeto');
    }
    final ticketsRaw = decoded['tickets'];
    if (ticketsRaw is! List) {
      throw FormatException('Campo obligatorio ausente: tickets');
    }
    return ticketsRaw
        .map(
          (item) =>
              ClashGachaTicket.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(growable: false);
  }
}
