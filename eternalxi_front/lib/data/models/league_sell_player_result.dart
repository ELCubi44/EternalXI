import 'package:eternal_xi/data/models/league_json_read.dart';

class LeagueSellPlayerResult {
  const LeagueSellPlayerResult({
    required this.idLiga,
    required this.idLigaJugador,
    required this.idUsuario,
    required this.valorActual,
    required this.cantidadVenta,
    required this.nuevoSaldo,
  });

  final int idLiga;
  final int idLigaJugador;
  final int idUsuario;
  final int valorActual;
  final int cantidadVenta;
  final int nuevoSaldo;

  factory LeagueSellPlayerResult.fromJson(Map<String, dynamic> json) {
    return LeagueSellPlayerResult(
      idLiga: readLeagueInt(json, const ['idLiga', 'id_liga']),
      idLigaJugador: readLeagueInt(json, const [
        'idLigaJugador',
        'id_liga_jugador',
      ]),
      idUsuario: readLeagueInt(json, const ['idUsuario', 'id_usuario']),
      valorActual: readLeagueInt(json, const ['valorActual', 'valor_actual']),
      cantidadVenta: readLeagueInt(json, const [
        'cantidadVenta',
        'cantidad_venta',
      ]),
      nuevoSaldo: readLeagueInt(json, const ['nuevoSaldo', 'nuevo_saldo']),
    );
  }
}
