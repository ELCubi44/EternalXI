import 'package:eternal_xi/core/utils/league_money_format.dart';

/// Textos y formato para la UI del mercado nocturno.
abstract final class LeagueNightMarketFormat {
  LeagueNightMarketFormat._();

  static String moneyInt(int value) {
    return LeagueMoneyFormat.euros(value.toDouble());
  }

  static String bidOrEmpty(int? amount) {
    if (amount == null) {
      return 'Sin pujas';
    }
    return moneyInt(amount);
  }

  static String myBidOrNone(int? amount) {
    if (amount == null) {
      return 'No has pujado';
    }
    return moneyInt(amount);
  }

  static String estadoLabel(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return '—';
    }
    return t;
  }

  static String posicionLabel(String raw) {
    final t = raw.trim();
    return t.isEmpty ? '—' : t;
  }

  /// `yyyy-MM-dd` → `dd/MM/yyyy` si aplica; si no, el texto original.
  static String fechaMercadoDisplay(String raw) {
    final t = raw.trim();
    final parts = t.split('-');
    if (parts.length == 3 &&
        parts[0].length == 4 &&
        parts[1].length == 2 &&
        parts[2].length == 2) {
      return '${parts[2]}/${parts[1]}/${parts[0]}';
    }
    return t.isEmpty ? '—' : t;
  }
}
