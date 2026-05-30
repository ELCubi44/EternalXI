import 'package:eternal_xi/data/models/league_activity_event.dart';
import 'package:eternal_xi/data/models/league_market_history_entry.dart';

/// Filtros del historial de mercado / liga.
abstract final class LeagueMarketHistoryFilters {
  LeagueMarketHistoryFilters._();

  static const all = 'ALL';
  static const adjudicacion = 'ADJUDICACION_MERCADO';
  static const compraDirecta = 'COMPRA_DIRECTA_DOBLE';
  static const acuerdo = 'ACUERDO_USUARIOS';
  static const venta = 'VENTA_MERCADO';
  static const expulsion = 'ADMIN_KICK';

  static const labels = <String, String>{
    all: 'Todo',
    adjudicacion: 'Subasta',
    compraDirecta: 'Compra x2',
    acuerdo: 'Traspasos',
    venta: 'Ventas',
    expulsion: 'Expulsiones',
  };
}

/// Filtros del historial de la tienda de recompensas.
abstract final class LeagueShopActivityFilters {
  LeagueShopActivityFilters._();

  static const all = 'ALL';
  static const packs = 'PACK_OPENED';
  static const roulette = 'COACH_ROULETTE';
  static const cards = 'CARD_REDEEMED';

  static const labels = <String, String>{
    all: 'Todo',
    packs: 'Sobres',
    roulette: 'Ruleta',
    cards: 'Cartas',
  };

  static bool matchesFilter(LeagueActivityEvent event, String filter) {
    if (filter == all) {
      return true;
    }
    final tipo = event.tipo.trim().toUpperCase();
    switch (filter) {
      case packs:
        return tipo == 'PACK_OPENED';
      case roulette:
        return tipo == 'COACH_ROULETTE' || tipo == 'COACH_ROULETTE_SPIN';
      case cards:
        return tipo == 'CARD_REDEEMED';
      default:
        return true;
    }
  }

  /// La tienda no muestra expulsiones ni cierres de jornada.
  static bool isShopEvent(LeagueActivityEvent event) {
    final tipo = event.tipo.trim().toUpperCase();
    return tipo != 'ADMIN_KICK' && tipo != 'ROUND_FINISHED';
  }
}

sealed class LeagueUnifiedHistoryItem {
  const LeagueUnifiedHistoryItem(this.sortDate);

  final DateTime? sortDate;
}

final class LeagueUnifiedMarketItem extends LeagueUnifiedHistoryItem {
  LeagueUnifiedMarketItem(this.entry) : super(entry.creadoEn);

  final LeagueMarketHistoryEntry entry;
}

final class LeagueUnifiedActivityItem extends LeagueUnifiedHistoryItem {
  LeagueUnifiedActivityItem(this.event) : super(event.creadoEn);

  final LeagueActivityEvent event;
}

bool leagueMarketHistoryMatchesFilter(
  LeagueUnifiedHistoryItem item,
  String filter,
) {
  if (filter == LeagueMarketHistoryFilters.all) {
    return true;
  }
  return switch (item) {
    LeagueUnifiedMarketItem(:final entry) =>
      entry.tipo.trim().toUpperCase() == filter,
    LeagueUnifiedActivityItem(:final event) =>
      filter == LeagueMarketHistoryFilters.expulsion &&
          event.tipo.trim().toUpperCase() == 'ADMIN_KICK',
  };
}
